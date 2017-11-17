//
//  waifu2xTests.swift
//  waifu2xTests
//
//  Created by 谢宜 on 2017/11/17.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import XCTest
@testable import waifu2x

class waifu2xTests: XCTestCase {
    
    var image: UIImage!
    
    override func setUp() {
        super.setUp()
        let bundle = Bundle(for: type(of: self))
        let path = bundle.path(forResource: "testimg", ofType: "jpg")
        let imgData = try! Data(contentsOf: URL(fileURLWithPath: path!))
        image = UIImage(data: imgData)
    }
    
    override func tearDown() {
        image = nil
        super.tearDown()
    }
    
    /// Test all waifu2x models using testimg.jpg
    func testModels() {
        for model in Model.all {
            debugPrint("Testing model \(model.rawValue)")
            let outImage = image.run(model: model)
            XCTAssertNotNil(outImage)
        }
    }
    
}
