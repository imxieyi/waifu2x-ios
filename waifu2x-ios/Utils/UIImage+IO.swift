//
//  UIImage+IO.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/15.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    public func saveToPhotoLibrary() {
        UIImageWriteToSavedPhotosAlbum(self, nil, nil, nil)
    }
    
}
