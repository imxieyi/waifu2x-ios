//
//  UIImage+Bicubic.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    public func scale2x() -> UIImage {
        let newsize = CGSize(width: size.width * 2, height: size.height * 2)
        UIGraphicsBeginImageContext(newsize)
        draw(in: CGRect(origin: .zero, size: newsize))
        let newimage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newimage!
    }
    
}
