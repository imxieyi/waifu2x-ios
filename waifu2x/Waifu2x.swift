//
//  Waifu2x.swift
//  waifu2x
//
//  Created by 谢宜 on 2017/11/18.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import Accelerate
import UIKit
import CoreML
import MetalKit

public class Waifu2x {
    
    /// The output block size.
    /// It is dependent on the model.
    /// Do not modify it until you are sure your model has a different number.
    static var block_size = 128
    
    /// The difference between output and input block size
    static let shrink_size = 7
    
    /// Do not exactly know its function
    /// However it can on average improve PSNR by 0.09
    /// https://github.com/nagadomi/waifu2x/commit/797b45ae23665a1c5e3c481c018e48e6f0d0e383
    static let clip_eta8: Float = 0.00196078411
    
    public static var interrupt = false
    
    static private var in_pipeline: BackgroundPipeline<CGRect>! = nil
    static private var model_pipeline: BackgroundPipeline<MLMultiArray>! = nil
    static private var out_pipeline: BackgroundPipeline<MLMultiArray>! = nil
    
    static public func run(_ image: UIImage!, model: Model!, _ callback: @escaping (String) -> Void = { _ in }) -> UIImage? {
        guard image != nil else {
            return nil
        }
        guard model != nil else {
            callback("finished")
            return image
        }
        Waifu2x.interrupt = false
        var hasalpha = image.cgImage?.alphaInfo != CGImageAlphaInfo.none
        debugPrint("With Alpha: \(hasalpha)")
        let channels = 4
        var alpha: [UInt8]! = nil
        if hasalpha {
            var u8Alpha = image.alpha()
            var floatAlpha = [Float](repeating: 0, count: u8Alpha.count)
            // Check if it really has alpha
            var minValue: Float = 1.0
            var minIndex: vDSP_Length = 0
            vDSP_vfltu8(&u8Alpha, 1, &floatAlpha, 1, vDSP_Length(u8Alpha.count))
            vDSP_minvi(&floatAlpha, 1, &minValue, &minIndex, vDSP_Length(u8Alpha.count))
            if minValue < 255.0 {
                alpha = u8Alpha
            } else {
                hasalpha = false
            }
        }
        debugPrint("Really With Alpha: \(hasalpha)")
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        var out_width: Int
        var out_height: Int
        var out_block_size: Int
        var out_scale: Int
        switch model {
        case .anime_noise0, .anime_noise1, .anime_noise2, .anime_noise3, .photo_noise0, .photo_noise1, .photo_noise2, .photo_noise3:
            Waifu2x.block_size = 128
            out_width = width
            out_height = height
            out_block_size = Waifu2x.block_size
            out_scale = 1
        default:
            Waifu2x.block_size = 142
            out_width = width * 2
            out_height = height * 2
            out_block_size = Waifu2x.block_size * 2
            out_scale = 2
        }
        let rects = image.getCropRects()
        // Prepare for output pipeline
        // Merge arrays into one array
        let normalize = { (input: Double) -> Double in
            let output = input * 255
            if output > 255 {
                return 255
            }
            if output < 0 {
                return 0
            }
            return output
        }
        let bufferSize = out_block_size * out_block_size * 3
        var imgData: [UInt8]
        // Alpha channel support
        imgData = [UInt8](repeating: 0, count: out_width * out_height * channels)
        var alpha_task: BackgroundTask? = nil
        if hasalpha {
            alpha_task = BackgroundTask("alpha") {
                if out_scale > 1 {
                    var outalpha: [UInt8]? = nil
                    if let metalBicubic = try? MetalBicubic() {
                        NSLog("Maximum texture size supported: %d", metalBicubic.maxTextureSize())
                        if out_width <= metalBicubic.maxTextureSize() && out_height <= metalBicubic.maxTextureSize() {
                            outalpha = metalBicubic.resizeSingle(alpha, width, height, Float(out_scale))
                        }
                    }
                    if outalpha != nil {
                        alpha = outalpha!
                    } else {
                        // Fallback to CPU scale
                        let bicubic = Bicubic(image: alpha, channels: 1, width: width, height: height)
                        alpha = bicubic.resize(scale: Float(out_scale))
                    }
                }
                for y in 0 ..< out_height {
                    for x in 0 ..< out_width {
                        imgData[(y * out_width + x) * channels + 3] = alpha[y * out_width + x]
                    }
                }
            }
        }
        // Output
        Waifu2x.out_pipeline = BackgroundPipeline<MLMultiArray>("out_pipeline", count: rects.count) { (index, array) in
            let rect = rects[index]
            let origin_x = Int(rect.origin.x) * out_scale
            let origin_y = Int(rect.origin.y) * out_scale
            let dataPointer = UnsafeMutableBufferPointer(start: array.dataPointer.assumingMemoryBound(to: Double.self),
                                                         count: bufferSize)
            var dest_x: Int
            var dest_y: Int
            var src_index: Int
            var dest_index: Int
            for channel in 0..<3 {
                for src_y in 0..<out_block_size {
                    for src_x in 0..<out_block_size {
                        dest_x = origin_x + src_x
                        dest_y = origin_y + src_y
                        src_index = src_y * out_block_size + src_x + out_block_size * out_block_size * channel
                        dest_index = (dest_y * out_width + dest_x) * channels + channel
                        imgData[dest_index] = UInt8(normalize(dataPointer[src_index]))
                    }
                }
            }
        }
        // Prepare for model pipeline
        // Run prediction on each block
        let mlmodel = model.getMLModel()
        Waifu2x.model_pipeline = BackgroundPipeline<MLMultiArray>("model_pipeline", count: rects.count) { (index, array) in
            out_pipeline.appendObject(try! mlmodel.prediction(input: array))
            callback("\((index * 100) / rects.count)")
        }
        // Start running model
        let expwidth = Int(image.size.width) + 2 * Waifu2x.shrink_size
        let expheight = Int(image.size.height) + 2 * Waifu2x.shrink_size
        var expanded = image.expand(withAlpha: hasalpha)
        callback("processing")
        Waifu2x.in_pipeline = BackgroundPipeline<CGRect>("in_pipeline", count: rects.count, task: { (index, rect) in
            let x = Int(rect.origin.x)
            let y = Int(rect.origin.y)
            let multi = try! MLMultiArray(shape: [3, NSNumber(value: Waifu2x.block_size + 2 * Waifu2x.shrink_size), NSNumber(value: Waifu2x.block_size + 2 * Waifu2x.shrink_size)], dataType: .float32)
            var x_new: Int
            var y_new: Int
            for y_exp in y..<(y + Waifu2x.block_size + 2 * Waifu2x.shrink_size) {
                for x_exp in x..<(x + Waifu2x.block_size + 2 * Waifu2x.shrink_size) {
                    x_new = x_exp - x
                    y_new = y_exp - y
                    multi[y_new * (Waifu2x.block_size + 2 * Waifu2x.shrink_size) + x_new] = NSNumber(value: expanded[y_exp * expwidth + x_exp])
                    var dest = y_new * (Waifu2x.block_size + 2 * Waifu2x.shrink_size) + x_new + (block_size + 2 * Waifu2x.shrink_size) * (block_size + 2 * Waifu2x.shrink_size)
                    multi[dest] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight])
                    dest = y_new * (Waifu2x.block_size + 2 * Waifu2x.shrink_size) + x_new + (block_size + 2 * Waifu2x.shrink_size) * (block_size + 2 * Waifu2x.shrink_size) * 2
                    multi[dest] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2])
                }
            }
            model_pipeline.appendObject(multi)
        })
        for i in 0..<rects.count {
            Waifu2x.in_pipeline.appendObject(rects[i])
        }
        Waifu2x.in_pipeline.wait()
        Waifu2x.model_pipeline.wait()
        callback("wait_alpha")
        alpha_task?.wait()
        Waifu2x.out_pipeline.wait()
        Waifu2x.in_pipeline = nil
        Waifu2x.model_pipeline = nil
        Waifu2x.out_pipeline = nil
        if Waifu2x.interrupt {
            return nil
        }
        callback("generate_output")
        let cfbuffer = CFDataCreate(nil, &imgData, out_width * out_height * channels)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
        if hasalpha {
             bitmapInfo |= CGImageAlphaInfo.last.rawValue
        } else {
            bitmapInfo |= CGImageAlphaInfo.noneSkipLast.rawValue
        }
        let cgImage = CGImage(width: out_width, height: out_height, bitsPerComponent: 8, bitsPerPixel: 8 * channels, bytesPerRow: out_width * channels, space: colorSpace, bitmapInfo: CGBitmapInfo.init(rawValue: bitmapInfo), provider: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        let outImage = UIImage(cgImage: cgImage!)
        callback("finished")
        return outImage
    }
    
}
