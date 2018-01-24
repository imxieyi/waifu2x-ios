//
//  UIImage+Bicubic.swift
//  waifu2x
//
//  Created by 谢宜 on 2017/12/29.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation

extension UIImage {
    
    /// Resize image using Hermite Bicubic Interpolation
    ///
    /// - Parameter scale: Scale factor
    /// - Returns: Generated image
    func bicubic(scale: Float) -> UIImage {
        
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let outw = Int(Float(width) * scale)
        let outh = Int(Float(height) * scale)
        
        let pixels = self.cgImage?.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixels!)
        let buffer = UnsafeBufferPointer(start: data, count: 4 * width * height)
        let arr = Array(buffer)
        
        let bicubic = Bicubic(image: arr, channels: 4, width: width, height: height)
        
        let scaled = bicubic.resize(scale: scale)
        
        // Generate output image
        let cfbuffer = CFDataCreate(nil, scaled, outw * outh * 4)!
        let dataProvider = CGDataProvider(data: cfbuffer)!
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big
        let cgImage = CGImage(width: outw, height: outh, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: outw * 4, space: colorSpace, bitmapInfo: bitmapInfo, provider: dataProvider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
        let outImage = UIImage(cgImage: cgImage!)
        
        return outImage
    }
    
}
