//
//  ViewController.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import CoreML
import waifu2x

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var inputview: UIImageView!
    @IBOutlet weak var outputview: UIImageView!
    
    @IBOutlet weak var progress: UILabel!
    
    var inputImage: UIImage! {
        didSet {
            inputview.image = inputImage
            debugPrint("Size: \(inputImage.size.width) x \(inputImage.size.height)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    let pickercontroller = UIImagePickerController()

    @IBAction func onPick(_ sender: Any) {
        pickercontroller.delegate = self
        pickercontroller.sourceType = .photoLibrary
        present(pickercontroller, animated: true, completion: nil)
    }
    
    @IBAction func onProcess(_ sender: Any) {
        guard inputImage != nil else {
            return
        }
        // Reference: https://stackoverflow.com/questions/24755558/measure-elapsed-time-in-swift
        let start = DispatchTime.now()
        let background = DispatchQueue(label: "background")
        progress.text = "Scaling..."
        background.async {
            let outimage = self.inputImage.run(model: .anime_noise2_scale2x, scale: 2)?.reload()
            let end = DispatchTime.now()
            let nanotime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanotime) / 1_000_000_000
            DispatchQueue.main.async {
                self.progress.text = "Time elapsed: \(timeInterval)"
                self.outputview.image = outimage
            }
        }
    }
    
    @IBAction func onSave(_ sender: Any) {
        guard let image = outputview.image else {
            let alert = UIAlertController(title: "Error", message: "You should process the image first!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        image.saveToPhotoLibrary()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        inputImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        pickercontroller.dismiss(animated: true, completion: nil)
    }
    
}
