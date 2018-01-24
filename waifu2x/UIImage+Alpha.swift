//
//  UIImage+Alpha.swift
//  waifu2x
//
//  Created by 谢宜 on 2017/12/29.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation

extension UIImage {
    
    func alpha() -> [UInt8] {
        let width = Int(size.width)
        let height = Int(size.height)
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height)
        let alphaOnly = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpace.init(name: CGColorSpace.linearGray)!, bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
        alphaOnly?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        var result: [UInt8] = []
        for i in 0 ..< width * height {
            result.append(data[i])
        }
        return result
    }
    
}
