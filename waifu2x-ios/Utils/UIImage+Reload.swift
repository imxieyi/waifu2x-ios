//
//  UIImage+Reload.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    /// Workaround: Apply two ML filters sequently will break the image
    ///
    /// - Returns: the reloaded image
    public func reload() -> UIImage? {
        let tmpfile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.png")
        let fm = FileManager.default
        if fm.fileExists(atPath: tmpfile.path) {
            try? fm.removeItem(at: tmpfile)
        }
        try! UIImagePNGRepresentation(self)?.write(to: tmpfile)
        let data = try! Data(contentsOf: tmpfile)
        let img = UIImage(data: data)
        if fm.fileExists(atPath: tmpfile.path) {
            try? fm.removeItem(at: tmpfile)
        }
        return img
    }
    
}
