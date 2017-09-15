# waifu2x on iOS

## Introduction
This is [CoreML](https://developer.apple.com/documentation/coreml) implementation of [waifu2x](https://github.com/nagadomi/waifu2x). You should [convert pre-trained models to CoreML format](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml). The pre-trained model can be obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe).

## Requirements
 - XCode 9+
 - iOS 11+
 
## Convert model
You can use the same method described in [MobileNet-CoreML](https://github.com/hollance/MobileNet-CoreML). **You should not specify any input and output layer in python script.**

## Benchmark
Run Denoise level 2 and Scale 2x model on a 3000*3328 png image:
### Environment
- **iPad** - waifu2x-ios on iPad Pro 10.5 with iOS 11.0 GM
- **PC** - waifu2x-caffe on Windows 10 16278 with [GTX 960M](https://www.geforce.com/hardware/notebook-gpus/geforce-gtx-960m)
### Result
|Device|Time(s)|
|---|---|
|iPad|126.2|
|PC|36.5|

## Demo
![](demo.png)

Image source: [https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476](https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476)
