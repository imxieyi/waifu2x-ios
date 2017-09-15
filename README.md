# waifu2x on iOS

## Introduction
This is a [CoreML](https://developer.apple.com/documentation/coreml) implementation of [waifu2x](https://github.com/nagadomi/waifu2x). The target of this project is to run waifu2x models right on iOS devices even without network.

## Requirements
 - XCode 9+
 - iOS 11+
 
## About models
You should [convert pre-trained models to CoreML format](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml) and import it to **XCode**. The pre-trained model can be obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe).
You can use the same method described in [MobileNet-CoreML](https://github.com/hollance/MobileNet-CoreML). **You should not specify any input and output layer in python script.**

## Benchmark
### Environment
- **iPhone** - waifu2x-ios on iPhone 6s with iOS 11.0 GM
- **iPad** - waifu2x-ios on iPad Pro 10.5 with iOS 11.0 GM
- **PC** - waifu2x-caffe on Windows 10 16278 with [GTX 960M](https://www.geforce.com/hardware/notebook-gpus/geforce-gtx-960m)
### Results
All of the tests are running `denoise level 2` and `scale 2x` model on anime-style images from [Pixiv](https://www.pixiv.net/).

#### Test1
*Image resolution: `600*849`*

Device|Time(s)
---|---
iPhone|16.7
iPad|7.2
PC|2.1

#### Test2
*Image resolution: `3000*3328`*

Device|Time(s)
---|---
iPhone|- *(No enough RAM)*
iPad|126.2
PC|37.5

## Demo
![](demo.png)

Image source: [https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476](https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476)
