//
//  Bicubic.swift
//  waifu2x
//
//  Created by 谢宜 on 2017/12/29.
//  Copyright © 2017年 xieyi. All rights reserved.
//
//  Reference: https://blog.demofox.org/2015/08/15/resizing-images-with-bicubic-interpolation/

import Foundation

/// Bicubic interpolation on image.
/// Extremely slow because it runs on CPU.
class Bicubic {
    
    let image: [UInt8]
    let channels: Int
    let width: Int
    let height: Int
    let pitch: Int
    
    /// Create Bicubic instance
    ///
    /// - Parameters:
    ///   - image: image stored in UInt8 array
    ///   - channels: # channels in image array
    ///   - width: width of original image
    ///   - height: height of original image
    init(image: [UInt8], channels: Int, width: Int, height: Int) {
        self.channels = channels
        self.width = width
        self.height = height
        self.image = image
        pitch = channels * width
    }
    
    private func clamped(_ v: Float, _ min: Float, _ max: Float) -> Float {
        if v < min {
            return min
        }
        if v > max {
            return max
        }
        return v
    }
    
    private func clamped(_ v: Int, _ min: Int, _ max: Int) -> Int {
        if v < min {
            return min
        }
        if v > max {
            return max
        }
        return v
    }
    
    /// Get pixel at specific point with protection of overflow
    ///
    /// - Parameters:
    ///   - x: x
    ///   - y: y
    ///   - c: channel
    /// - Returns: pixel
    private func getPixelClamped(x: Int, y: Int, c: Int) -> Float {
        let xx = clamped(x, 0, width - 1)
        let yy = clamped(y, 0, height - 1)
        return Float(image[yy * pitch + xx + c])
    }
    
    /// t is a value that goes from 0 to 1 to interpolate in a C1 continuous way across uniformly sampled data points.
    /// when t is 0, this will return B.  When t is 1, this will return C.  Inbetween values will return an interpolation
    /// between B and C.  A and B are used to calculate slopes at the edges.
    private func cubicHermite(_ A: Float, _ B: Float, _ C: Float, _ D: Float, t: Float) -> Float {
        let a = -A / 2 + (3 * B) / 2 - (3 * C) / 2 + D / 2
        let b = A - (5 * B) / 2 + 2 * C - D / 2
        let c = -A / 2 + C / 2
        let d = B
        return a * t * t * t + b * t * t + c * t + d
    }

    private func sampleBicubic(u: Float, v: Float, c: Int) -> UInt8 {
        // calculate coordinates -> also need to offset by half a pixel to keep image from shifting down and left half a pixel
        let x = u * Float(width) - 0.5
        let xint = Int(x)
        let xfract = x - floor(x)
        let y = v * Float(height) - 0.5
        let yint = Int(y)
        let yfract = y - floor(y)
        
        // 1st row
        let p00 = getPixelClamped(x: xint - 1, y: yint - 1, c: c)
        let p10 = getPixelClamped(x: xint + 0, y: yint - 1, c: c)
        let p20 = getPixelClamped(x: xint + 1, y: yint - 1, c: c)
        let p30 = getPixelClamped(x: xint + 2, y: yint - 1, c: c)
        
        // 2nd row
        let p01 = getPixelClamped(x: xint - 1, y: yint + 0, c: c)
        let p11 = getPixelClamped(x: xint + 0, y: yint + 0, c: c)
        let p21 = getPixelClamped(x: xint + 1, y: yint + 0, c: c)
        let p31 = getPixelClamped(x: xint + 2, y: yint + 0, c: c)
        
        // 3rd row
        let p02 = getPixelClamped(x: xint - 1, y: yint + 1, c: c)
        let p12 = getPixelClamped(x: xint + 0, y: yint + 1, c: c)
        let p22 = getPixelClamped(x: xint + 1, y: yint + 1, c: c)
        let p32 = getPixelClamped(x: xint + 2, y: yint + 1, c: c)
        
        // 4th row
        let p03 = getPixelClamped(x: xint - 1, y: yint + 2, c: c)
        let p13 = getPixelClamped(x: xint + 0, y: yint + 2, c: c)
        let p23 = getPixelClamped(x: xint + 1, y: yint + 2, c: c)
        let p33 = getPixelClamped(x: xint + 2, y: yint + 2, c: c)
        
        // interpolate bi-cubically
        // Clamp the values since the curve can put the value below 0 or above 255
        let col0 = cubicHermite(p00, p10, p20, p30, t: xfract)
        let col1 = cubicHermite(p01, p11, p21, p31, t: xfract)
        let col2 = cubicHermite(p02, p12, p22, p32, t: xfract)
        let col3 = cubicHermite(p03, p13, p23, p33, t: xfract)
        var value = cubicHermite(col0, col1, col2, col3, t: yfract)
        value = clamped(value, 0, 255)
        
        return UInt8(value)
    }
    
    /// Resize the image
    ///
    /// - Parameter scale: Scale factor
    /// - Returns: Scaled image in UInt8 array
    func resize(scale: Float) -> [UInt8] {
        let outw = Int(Float(width) * scale)
        let outh = Int(Float(height) * scale)
        let outp = outw * channels
        var out = [UInt8](repeating: 0, count: outw * outh * channels)
        for y in 0 ..< outh {
            let v = Float(y) / Float(outh - 1)
            for x in 0 ..< outw {
                for c in 0 ..< channels {
                    let u = Float(x) / Float(outw - 1)
                    let sample = sampleBicubic(u: u, v: v, c: c)
                    out[y * outp + x + c] = sample
                }
            }
        }
        return out
    }
    
}
