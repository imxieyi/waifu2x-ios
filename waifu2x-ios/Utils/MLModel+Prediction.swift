//
//  MLModel+Prediction.swift
//  waifu2x-ios
//
//  Created by 谢宜 on 2017/11/5.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import CoreML

/// Model Prediction Input Type
class Waifu2xInput: MLFeatureProvider {
    
    /// input as whatever array of doubles
    var input: MLMultiArray
    
    var featureNames: Set<String> {
        get {
            return ["input"]
        }
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "input") {
            return MLFeatureValue(multiArray: input)
        }
        return nil
    }
    
    init(_ input: MLMultiArray) {
        self.input = input
    }
    
}

// MARK: - Make coreml models more generic to use
extension MLModel {
    
    public func prediction(input: MLMultiArray) throws -> MLMultiArray {
        let input_ = Waifu2xInput(input)
        let outFeatures = try self.prediction(from: input_)
        let result = outFeatures.featureValue(for: "conv7")!.multiArrayValue!
        return result
    }
    
}
