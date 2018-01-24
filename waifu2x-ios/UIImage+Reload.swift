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
    public func reload(jpg: Bool = false, quality: CGFloat = 0.9) -> UIImage? {
        var tmpfile: URL
        if jpg {
            tmpfile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.jpg")
        } else {
            tmpfile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("temp.png")
        }
        let fm = FileManager.default
        if fm.fileExists(atPath: tmpfile.path) {
            try? fm.removeItem(at: tmpfile)
        }
        if jpg {
            try! UIImageJPEGRepresentation(self, quality)?.write(to: tmpfile)
        } else {
            try! UIImagePNGRepresentation(self)?.write(to: tmpfile)
        }
        let img = UIImage(contentsOfFile: tmpfile.path)
        return img
    }
    
}
