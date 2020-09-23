//
//  MPSMLModel.swift
//  CoreML-MPS
//
//  Created by xieyi on 2018/12/20.
//  Copyright © 2018 xieyi. All rights reserved.
//

import Foundation
import UIKit
import MetalPerformanceShaders
import MetalKit

public class MPSMLModel {
    
    let rawModel: RawMLModel
    
    private var xScaleFactor: Int = 1
    private var yScaleFactor: Int = 1

    // Prevent conv from deiniting
    var convs: [MPSCNNKernel] = []
    // Prevent MPSDS from deiniting
    var convSources: [MPSCNNConvolutionDataSource] = []
    
    public init(model: String, bundle: Bundle) throws {
        rawModel = try RawMLModel(model, bundle)
    }
    
    public func createGraph(device: MTLDevice, input: String, output: String) throws {
        
        try rawModel.load()
        try rawModel.construct()
        
        var node: MLNode? = rawModel.graph[input]
        var mpsDes: MPSDS? = nil
        var deconv: Bool = false
        
        guard node != nil else {
            throw MLModelError.nodeNotExist("Input feature \(input) does not exist")
        }
        
        convs.removeAll()
        convSources.removeAll()
        
        while node != nil && node?.name != output {
            let name = (node?.name)!
            let layer = rawModel.layers[name]
            if layer == nil {
                node = node?.top
                continue
            }
            let type = layer!["type"].stringValue
            if type == "activation" {
                if mpsDes != nil {
                    mpsDes?.addRelu(alpha: layer!["alpha"].floatValue)
                    var conv: MPSCNNKernel
                    if deconv {
                        conv = MPSCNNConvolutionTranspose(device: device, weights: mpsDes!)
                    } else {
                        conv = MPSCNNConvolution(device: device, weights: mpsDes!)
                    }
                    conv.padding = FullSizeCenteredPadding()
                    convs.append(conv)
                    convSources.append(mpsDes!)
                    mpsDes = nil
                } else {
                    throw MLModelError.unsupportedFormat("No conv before \(name)")
                }
            } else if type == "convolution" || type == "deconvolution" {
                if mpsDes != nil {
                    var conv: MPSCNNKernel
                    if deconv {
                        conv = MPSCNNConvolutionTranspose(device: device, weights: mpsDes!)
                    } else {
                        conv = MPSCNNConvolution(device: device, weights: mpsDes!)
                    }
                    conv.padding = FullSizeCenteredPadding()
                    convs.append(conv)
                    convSources.append(mpsDes!)
                }
                let w = rawModel.blobs[layer!["blob_weights"].intValue]
                var b: Data? = nil
                if layer!["has_biases"].intValue == 1 {
                    b = rawModel.blobs[layer!["blob_biases"].intValue]
                }
                let kw = layer!["Nx"].intValue
                let kh = layer!["Ny"].intValue
                let ifc = layer!["K"].intValue
                let ofc = layer!["C"].intValue
                deconv = (type == "deconvolution")
                mpsDes = MPSDS(label: name, w: w, b: b, kw: kw, kh: kh, ifc: ifc, ofc: ofc, deconv: deconv)
                if let xStride = layer!["stride_x"].int {
                    if let yStride = layer!["stride_y"].int {
                        mpsDes?.setStride(x: xStride, y: yStride)
                        if xScaleFactor < xStride {
                            xScaleFactor = xStride
                        }
                        if yScaleFactor < yStride {
                            yScaleFactor = yStride
                        }
                    }
                }
            } else {
                throw MLModelError.unsupportedFormat("Layer type \(type) unsupported")
            }
            node = node?.top
        }
        
        guard node?.name == output else {
            throw MLModelError.nodeNotExist("Out feature \(output) does not exist on path from input \(input)")
        }
        
        // Output layer
        if mpsDes != nil {
            var conv: MPSCNNKernel
            if deconv {
                conv = MPSCNNConvolutionTranspose(device: device, weights: mpsDes!)
            } else {
                conv = MPSCNNConvolution(device: device, weights: mpsDes!)
            }
            conv.padding = FullSizeCenteredPadding()
            convs.append(conv)
            convSources.append(mpsDes!)
        }
    }
    
    public func encode(to commandBuffer: MTLCommandBuffer, input: MPSImage, output: MPSImage) {
        var currentImage = input
        for i in 0..<convs.count - 1 {
            currentImage = convs[i].encode(commandBuffer: commandBuffer, sourceImage: currentImage)
        }
        convs.last?.encode(commandBuffer: commandBuffer, sourceImage: currentImage, destinationImage: output)
    }
    
    public func encode(to commandBuffer: MTLCommandBuffer, input: MPSImage) -> MPSImage? {
        let outDesc = MPSImageDescriptor(channelFormat: input.featureChannelFormat, width: input.width * xScaleFactor, height: input.height * yScaleFactor, featureChannels: input.featureChannels)
        let outImage = MPSTemporaryImage(commandBuffer: commandBuffer, imageDescriptor: outDesc)
        encode(to: commandBuffer, input: input, output: outImage)
        return outImage
    }
    
}

class FullSizeCenteredPadding: NSObject, MPSNNPadding {
    
    static var supportsSecureCoding: Bool = false
    
    func encode(with aCoder: NSCoder) {
        fatalError()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override init() {
        super.init()
    }
    
    func paddingMethod() -> MPSNNPaddingMethod {
        return [.custom, .sizeFull, .centered]
    }
    
    func destinationImageDescriptor(forSourceImages sourceImages: [MPSImage], sourceStates: [MPSState]?, for kernel: MPSKernel, suggestedDescriptor inDescriptor: MPSImageDescriptor) -> MPSImageDescriptor {
        if let kernel = kernel as? MPSCNNConvolution {
            kernel.edgeMode = .clamp
        }
        if let kernel = kernel as? MPSCNNConvolutionTranspose {
            kernel.edgeMode = .clamp
        }
        return MPSImageDescriptor(channelFormat: .float16, width: inDescriptor.width, height: inDescriptor.height, featureChannels: inDescriptor.featureChannels)
    }
    
}
