//
//  MLNode.swift
//  CoreML-MPS
//
//  Created by xieyi on 2018/12/20.
//  Copyright © 2018 xieyi. All rights reserved.
//

import Foundation

class MLNode {
    
    weak var top: MLNode? = nil
    weak var bottom: MLNode? = nil
    var name: String
    
    init(_ name: String) {
        self.name = name
    }
    
}
