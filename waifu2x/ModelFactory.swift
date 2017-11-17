//
//  ModelFactory.swift
//  waifu2x-ios
//
//  Created by 谢宜 on 2017/11/5.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import CoreML

fileprivate class Dummy: Any {
}

public enum Model: String {
    case anime_noise0 = "anime_noise0_model"
    case anime_noise1 = "anime_noise1_model"
    case anime_noise2 = "anime_noise2_model"
    case anime_noise3 = "anime_noise3_model"
    case anime_scale2x = "up_anime_scale2x_model"
    case anime_noise0_scale2x = "up_anime_noise0_scale2x_model"
    case anime_noise1_scale2x = "up_anime_noise1_scale2x_model"
    case anime_noise2_scale2x = "up_anime_noise2_scale2x_model"
    case anime_noise3_scale2x = "up_anime_noise3_scale2x_model"
    case photo_noise0 = "photo_noise0_model"
    case photo_noise1 = "photo_noise1_model"
    case photo_noise2 = "photo_noise2_model"
    case photo_noise3 = "photo_noise3_model"
    case photo_scale2x = "up_photo_scale2x_model"
    case photo_noise0_scale2x = "up_photo_noise0_scale2x_model"
    case photo_noise1_scale2x = "up_photo_noise1_scale2x_model"
    case photo_noise2_scale2x = "up_photo_noise2_scale2x_model"
    case photo_noise3_scale2x = "up_photo_noise3_scale2x_model"
    // For the convience of unit test
    static let all: [Model] = [.anime_noise0, .anime_noise1, .anime_noise2, .anime_noise3, .anime_scale2x,
                               .anime_noise0_scale2x, .anime_noise1_scale2x, .anime_noise2_scale2x, .anime_noise3_scale2x,
                               .photo_noise0, .photo_noise1, .photo_noise2, .photo_noise3,
                               .photo_noise0_scale2x, .anime_noise1_scale2x, .anime_noise2_scale2x, .anime_noise3_scale2x, ]
    public func getMLModel() -> MLModel {
        let bundle = Bundle(for: Dummy.self)
        let assetPath = bundle.url(forResource: self.rawValue, withExtension: "mlmodelc")
        return try! MLModel(contentsOf: assetPath!)
    }
}
