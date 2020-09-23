//
//  ViewController.swift
//  waifu2x-ios
//
//  Created by xieyi on 2017/9/14.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation
import waifu2x
import BBMetalImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var inputview: UIImageView!
    @IBOutlet weak var outputview: UIImageView!
    
    @IBOutlet weak var pickBtn: UIButton!
    @IBOutlet weak var processBtn: UIButton!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var progress: UILabel!
    
    var inputImage: UIImage! {
        didSet {
            inputview.image = inputImage
            debugPrint("Size: \(inputImage.size.width) x \(inputImage.size.height)")
        }
    }
    
    var videoSource: BBMetalVideoSource!
    var videoWriter: BBMetalVideoWriter!

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
        pickBtn.isEnabled = false
        processBtn.isEnabled = false
        saveBtn.isEnabled = false
        background.async {
            let outimage = Waifu2x.run(self.inputImage, model: Model.anime_noise1_scale2x)?.reload()
            let end = DispatchTime.now()
            let nanotime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanotime) / 1_000_000_000
            DispatchQueue.main.async {
                self.progress.text = "Time elapsed: \(timeInterval)"
                self.outputview.image = outimage
                self.pickBtn.isEnabled = true
                self.processBtn.isEnabled = true
                self.saveBtn.isEnabled = true
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
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    @IBAction func onVideoTest(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeVideo), String(kUTTypeMPEG4)], in: .open)
        documentPicker.allowsMultipleSelection = false
        documentPicker.shouldShowFileExtensions = true
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        inputImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        pickercontroller.dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let inputUrl = urls.first else {
            return
        }
        let outputUrl = FileManager.default.temporaryDirectory.appendingPathComponent("output.mp4")
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            try! FileManager.default.removeItem(at: outputUrl)
        }
        
        let filter = Waifu2xFilter(model: "up_anime_noise3_scale2x_model")
        
        guard let track = AVURLAsset(url: inputUrl).tracks(withMediaType: AVMediaType.video).first else {
            return
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        
        let frameSize = BBMetalIntSize(width: Int(size.width) * filter.scaleFactor,
                                       height: Int(size.height) * filter.scaleFactor)
        
        videoWriter = BBMetalVideoWriter(url: outputUrl, frameSize: frameSize)
        
        videoSource = BBMetalVideoSource(url: inputUrl)!
        videoSource.benchmark = true
        
        videoSource.audioConsumer = videoWriter
        
        videoSource.add(consumer: filter).add(consumer: videoWriter)
        
        videoWriter.start()
        
        print("Output size:", frameSize.width, frameSize.height)
        print("Output path:", outputUrl)
        
        var index = 0
        let startTime = Date()
        videoSource.start(progress: { (time) in
            index += 1
            DispatchQueue.main.async {
                let stats = String(format: "Frame: %d\tTime: %d\tAvg FPS:%.2f", index, time.value, Double(index) / Date().timeIntervalSince(startTime))
                self.progress.text = stats
            }
        }) { (success) in
            self.videoWriter.finish {
                print("finished")
                DispatchQueue.main.async {
                    self.progress.text = String(format: "Finished. Avg FPS:%.2f", Double(index) / Date().timeIntervalSince(startTime))
                }
            }
        }
    }
    
}
