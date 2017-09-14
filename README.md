# waifu2x on iOS

## Introduction
This is [CoreML](https://developer.apple.com/documentation/coreml) implementation of [waifu2x](https://github.com/nagadomi/waifu2x). You should [convert pre-trained models to CoreML format](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml). The pre-trained model can be obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe).

## Requirements
 - XCode 9+
 - iOS 11+e
 
## Convert model
You can use the same method described in [MobileNet-CoreML](https://github.com/hollance/MobileNet-CoreML). **You should not specify any input and output layer in python script.**

## Demo
![](demo.png)

Running on iPad Pro 10.5

Image source: [https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476](https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476)
