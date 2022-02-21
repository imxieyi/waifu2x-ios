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
        let width = Int(cgImage!.width)
        let height = Int(cgImage!.height)
        var data = [UInt8](repeating: 0, count: width * height)
        data.withUnsafeMutableBytes { pointer in
            let alphaOnly = CGContext(data: pointer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpace.init(name: CGColorSpace.linearGray)!, bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue)
            alphaOnly!.draw(cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return data
    }
    
}
