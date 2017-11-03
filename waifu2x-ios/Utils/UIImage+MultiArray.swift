//
//  UIImage+MultiArray.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import CoreML

/// The output block size.
/// It is dependent on the model.
/// Do not modify it until you are sure your model has a different number.
var block_size = 128

/// The difference of output and input block size
let shrink_size = 7

extension UIImage {
    
    public func getCroppedMultiArray(rects: [CGRect]) -> [MLMultiArray] {
        let expwidth = Int(self.size.width) + 2 * shrink_size
        let expheight = Int(self.size.height) + 2 * shrink_size
        let expanded = expand()
        var arrs = [MLMultiArray!].init(repeating: nil, count: rects.count)
        autoreleasepool {
            let pool = ThreadPool<CGRect>()
            pool.run(objs: rects, task: { (i, rect) in
                let x = Int(rect.origin.x)
                let y = Int(rect.origin.y)
                let multi = try! MLMultiArray(shape: [3, NSNumber(value: block_size + 2 * shrink_size), NSNumber(value: block_size + 2 * shrink_size)], dataType: .float32)
                for y_exp in y..<(y + block_size + 2 * shrink_size) {
                    for x_exp in x..<(x + block_size + 2 * shrink_size) {
                        let x_new = x_exp - x
                        let y_new = y_exp - y
                        multi[y_new * (block_size + 2 * shrink_size) + x_new] = NSNumber(value: expanded[y_exp * expwidth + x_exp])
                        multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size)] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight])
                        multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size) * 2] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2])
                    }
                }
                arrs[i] = multi
            })
        }
        return arrs
    }
    
    /// Expand the original image by shrink_size and store rgb in float array.
    /// The model will shrink the input image by 7 px.
    ///
    /// - Returns: Float array of rgb values
    public func expand() -> [Float] {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        let exwidth = width + 2 * shrink_size
        let exheight = height + 2 * shrink_size
        
        let pixels = self.cgImage?.dataProvider?.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixels!)
        
        var arr = [Float](repeating: 0, count: 3 * exwidth * exheight)
        
        var xx, yy, pixel: Int
        var r, g, b: UInt8
        var fr, fg, fb: Float
        // http://www.jianshu.com/p/516f01fed6e4
        for y in 0..<height {
            for x in 0..<width {
                xx = x + shrink_size
                yy = y + shrink_size
                pixel = (width * y + x) * 4
                r = data[pixel]
                g = data[pixel + 1]
                b = data[pixel + 2]
                // !!! rgb values are from 0 to 1
                // https://github.com/chungexcy/waifu2x-new/blob/master/image_test.py
                fr = Float(r) / 255
                fg = Float(g) / 255
                fb = Float(b) / 255
                arr[yy * exwidth + xx] = fr
                arr[yy * exwidth + xx + exwidth * exheight] = fg
                arr[yy * exwidth + xx + exwidth * exheight * 2] = fb
            }
        }
        // Top-left corner
        pixel = 0
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        for y in 0..<shrink_size {
            for x in 0..<shrink_size {
                arr[y * exwidth + x] = fr
                arr[y * exwidth + x + exwidth * exheight] = fg
                arr[y * exwidth + x + exwidth * exheight * 2] = fb
            }
        }
        // Top-right corner
        pixel = (width - 1) * 4
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        for y in 0..<shrink_size {
            for x in width+shrink_size..<width+2*shrink_size {
                arr[y * exwidth + x] = fr
                arr[y * exwidth + x + exwidth * exheight] = fg
                arr[y * exwidth + x + exwidth * exheight * 2] = fb
            }
        }
        // Bottom-left corner
        pixel = (width * (height - 1)) * 4
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        for y in height+shrink_size..<height+2*shrink_size {
            for x in 0..<shrink_size {
                arr[y * exwidth + x] = fr
                arr[y * exwidth + x + exwidth * exheight] = fg
                arr[y * exwidth + x + exwidth * exheight * 2] = fb
            }
        }
        // Bottom-right corner
        pixel = (width * (height - 1) + (width - 1)) * 4
        r = data[pixel]
        g = data[pixel + 1]
        b = data[pixel + 2]
        fr = Float(r) / 255
        fg = Float(g) / 255
        fb = Float(b) / 255
        for y in height+shrink_size..<height+2*shrink_size {
            for x in width+shrink_size..<width+2*shrink_size {
                arr[y * exwidth + x] = fr
                arr[y * exwidth + x + exwidth * exheight] = fg
                arr[y * exwidth + x + exwidth * exheight * 2] = fb
            }
        }
        // Top & bottom bar
        for x in 0..<width {
            pixel = x * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            xx = x + shrink_size
            for y in 0..<shrink_size {
                arr[y * exwidth + xx] = fr
                arr[y * exwidth + xx + exwidth * exheight] = fg
                arr[y * exwidth + xx + exwidth * exheight * 2] = fb
            }
            pixel = (width * (height - 1) + x) * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            xx = x + shrink_size
            for y in height+shrink_size..<height+2*shrink_size {
                arr[y * exwidth + xx] = fr
                arr[y * exwidth + xx + exwidth * exheight] = fg
                arr[y * exwidth + xx + exwidth * exheight * 2] = fb
            }
        }
        // Left & right bar
        for y in 0..<height {
            pixel = (width * y) * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            yy = y + shrink_size
            for x in 0..<shrink_size {
                arr[yy * exwidth + x] = fr
                arr[yy * exwidth + x + exwidth * exheight] = fg
                arr[yy * exwidth + x + exwidth * exheight * 2] = fb
            }
            pixel = (width * y + (width - 1)) * 4
            r = data[pixel]
            g = data[pixel + 1]
            b = data[pixel + 2]
            fr = Float(r) / 255
            fg = Float(g) / 255
            fb = Float(b) / 255
            yy = y + shrink_size
            for x in width+shrink_size..<width+2*shrink_size {
                arr[yy * exwidth + x] = fr
                arr[yy * exwidth + x + exwidth * exheight] = fg
                arr[yy * exwidth + x + exwidth * exheight * 2] = fb
            }
        }
        return arr
    }
    
}
