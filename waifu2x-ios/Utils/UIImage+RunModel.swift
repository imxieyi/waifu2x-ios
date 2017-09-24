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

public enum Model {
    case anime_noise0
    case anime_noise1
    case anime_noise2
    case anime_noise3
    case anime_scale2x
    case photo_noise0
    case photo_noise1
    case photo_noise2
    case photo_noise3
    case photo_scale2x
}

extension UIImage {
    
    public func run(model: Model) -> UIImage? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        var resultArrays: [MLMultiArray] = []
        let rects = getCropRects()
        let multis = getCroppedMultiArray(rects: rects)
        // Run prediction on each block
        switch model {
        case .anime_noise0:
            let model = anime_noise0_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .anime_noise1:
            let model = anime_noise1_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .anime_noise2:
            let model = anime_noise2_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .anime_noise3:
            let model = anime_noise3_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .anime_scale2x:
            let model = anime_scale2x_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .photo_noise0:
            let model = photo_noise0_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .photo_noise1:
            let model = photo_noise1_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .photo_noise2:
            let model = photo_noise2_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .photo_noise3:
            let model = photo_noise3_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        case .photo_scale2x:
            let model = photo_scale2x_model()
            for multi in multis {
                let result = try! model.prediction(input: multi)
                guard let resultArray = result.featureValue(for: "conv7")?.multiArrayValue else {
                    return nil
                }
                resultArrays.append(resultArray)
            }
        }
        
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
        let bufferSize = block_size * block_size * 3
        var imgData = [UInt8].init(repeating: 0, count: width * height * 3)
        let pool = ThreadPool<CGRect>()
        pool.run(objs: rects) { (index, rect) in
            autoreleasepool {
                let origin_x = Int(rect.origin.x)
                let origin_y = Int(rect.origin.y)
                let array = resultArrays[index]
                let dataPointer = UnsafeMutableBufferPointer(start: array.dataPointer.assumingMemoryBound(to: Double.self),
                                                             count: bufferSize)
                for channel in 0..<3 {
                    for src_y in 0..<block_size {
                        for src_x in 0..<block_size {
                            let dest_x = origin_x + src_x
                            let dest_y = origin_y + src_y
                            let src_index = src_y * 128 + src_x + block_size * block_size * channel
                            let dest_index = (dest_y * width + dest_x) * 3 + channel
                            imgData[dest_index] = UInt8(normalize(dataPointer[src_index]))
                        }
                    }
                }
            }
        }
        let cfbuffer = CFDataCreate(nil, &imgData, width * height * 3)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big
        let cgImage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 24, bytesPerRow: width * 3, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        let outImage = UIImage(cgImage: cgImage!)
        return outImage
    }
    
}
