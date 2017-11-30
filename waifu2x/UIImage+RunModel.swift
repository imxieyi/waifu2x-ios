//
//  UIImage+RunModel.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import UIKit
import CoreML

/// The output block size.
/// It is dependent on the model.
/// Do not modify it until you are sure your model has a different number.
var block_size = 128

/// The difference of output and input block size
let shrink_size = 7

extension UIImage {
    
    public func run(model: Model, scale: CGFloat = 1) -> UIImage? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        switch model {
        case .anime_noise0, .anime_noise1, .anime_noise2, .anime_noise3, .photo_noise0, .photo_noise1, .photo_noise2, .photo_noise3:
            block_size = 128
        default:
            block_size = 142
        }
        let rects = getCropRects()
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
        let out_block_size = block_size * Int(scale)
        let out_width = width * Int(scale)
        let out_height = height * Int(scale)
        let bufferSize = out_block_size * out_block_size * 3
        var imgData = [UInt8].init(repeating: 0, count: out_width * out_height * 3)
        let out_pipeline = BackgroundPipeline<MLMultiArray>("out_pipeline", count: rects.count) { (index, array) in
            let rect = rects[index]
            let origin_x = Int(rect.origin.x * scale)
            let origin_y = Int(rect.origin.y * scale)
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
                        dest_index = (dest_y * out_width + dest_x) * 3 + channel
                        imgData[dest_index] = UInt8(normalize(dataPointer[src_index]))
                    }
                }
            }
        }
        // Prepare for model pipeline
        // Run prediction on each block
        let mlmodel = model.getMLModel()
        let model_pipeline = BackgroundPipeline<MLMultiArray>("model_pipeline", count: rects.count) { (index, array) in
            out_pipeline.appendObject(try! mlmodel.prediction(input: array))
        }
        // Start running model
        let expwidth = Int(self.size.width) + 2 * shrink_size
        let expheight = Int(self.size.height) + 2 * shrink_size
        let expanded = expand()
        for rect in rects {
            let x = Int(rect.origin.x)
            let y = Int(rect.origin.y)
            let multi = try! MLMultiArray(shape: [3, NSNumber(value: block_size + 2 * shrink_size), NSNumber(value: block_size + 2 * shrink_size)], dataType: .float32)
            var x_new: Int
            var y_new: Int
            for y_exp in y..<(y + block_size + 2 * shrink_size) {
                for x_exp in x..<(x + block_size + 2 * shrink_size) {
                    x_new = x_exp - x
                    y_new = y_exp - y
                    multi[y_new * (block_size + 2 * shrink_size) + x_new] = NSNumber(value: expanded[y_exp * expwidth + x_exp])
                    multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size)] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight])
                    multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size) * 2] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2])
                }
            }
            model_pipeline.appendObject(multi)
        }
        model_pipeline.wait()
        out_pipeline.wait()
        let cfbuffer = CFDataCreate(nil, &imgData, out_width * out_height * 3)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big
        let cgImage = CGImage(width: out_width, height: out_height, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: out_width * 3, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        let outImage = UIImage(cgImage: cgImage!)
        return outImage
    }
    
}
