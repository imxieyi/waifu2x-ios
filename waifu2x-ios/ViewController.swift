//
//  ViewController.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet weak var inputview: UIImageView!
    @IBOutlet weak var outputview: UIImageView!
    
    let model = noise2_model()
    var inputImage: UIImage!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let path = Bundle.main.path(forResource: "37872248_p0", ofType: "jpg")
        inputImage = UIImage(imageLiteralResourceName: path!)
        inputview.image = inputImage
        //outputview.image = inputImage.scale2x()
    }

    @IBAction func onProcess(_ sender: Any) {
        outputview.image = inputImage.scale2x().reload()?.run(model: .noise2)?.reload()?.run(model: .scale2)
    }
}

