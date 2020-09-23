//
//  Waifu2xFilter.swift
//  waifu2x-ios
//
//  Created by xieyi on 2020/9/23.
//  Copyright © 2020 xieyi. All rights reserved.
//

import Foundation
import MetalPerformanceShaders
import BBMetalImage
import CoreML_MPS
import waifu2x

class Waifu2xFilter: BBMetalBaseFilter {
    
    var model: String {
        didSet {
            _mpsModel = nil
        }
    }
    
    var scaleFactor: Int {
        if model.contains("2x") {
            return 2
        }
        return 1
    }
    
    private var mpsModel: MPSMLModel {
        if let k = _mpsModel { return k }
        let k = try! MPSMLModel(model: model, bundle: .init(for: Waifu2x.self))
        try! k.createGraph(device: BBMetalDevice.sharedDevice, input: "input", output: "conv7")
        _mpsModel = k
        return k
    }
    private var _mpsModel: MPSMLModel!
    
    public init(model: String) {
        self.model = model
        super.init(kernelFunctionName: "", useMPSKernel: true)
    }
    
    override func outputTextureSize(withInputTextureSize inputSize: BBMetalIntSize) -> BBMetalIntSize {
        return BBMetalIntSize(width: scaleFactor * inputSize.width, height: scaleFactor * inputSize.height)
    }
    
    public override func encodeMPSKernel(into commandBuffer: MTLCommandBuffer) {
        let sourceImage = MPSImage(texture: _sources.first!.texture!, featureChannels: 3)
        let destImage = MPSImage(texture: _outputTexture!, featureChannels: 3)
        mpsModel.encode(to: commandBuffer, input: sourceImage, output: destImage)
    }
    
}
