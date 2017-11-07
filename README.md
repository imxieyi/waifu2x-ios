# waifu2x on iOS
[![](https://img.shields.io/github/last-commit/imxieyi/waifu2x-ios/store-version.svg)](https://github.com/imxieyi/waifu2x-ios/commits/store-version)
[![](https://img.shields.io/itunes/v/1286485858.svg)](https://itunes.apple.com/app/waifu2x/id1286485858)
[![](https://img.shields.io/github/license/imxieyi/waifu2x-ios.svg)](https://github.com/imxieyi/waifu2x-ios/blob/master/LICENSE)

[![](appstore.svg)](https://itunes.apple.com/app/waifu2x/id1286485858)

## Introduction
This is a [Core ML](https://developer.apple.com/documentation/coreml) implementation of [waifu2x](https://github.com/nagadomi/waifu2x). The target of this project is to run waifu2x models right on iOS devices even without network.

## Requirements
 - XCode 9+
 - iOS 11+
 
## About models
This repository includes all the models converted from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe). **If you want to dig into Core ML, it is recommended that you should convert them by yourself.**

You can [convert pre-trained models to Core ML format](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml) and then import them to **XCode**. The pre-trained model can be obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe).

You can use the same method described in [MobileNet-CoreML](https://github.com/hollance/MobileNet-CoreML). **You should not specify any input and output layer in python script.**

**A working model should have input and output like the following example:**

![](screenshots/model_example.png)

## Benchmark
### Environment
- **iPhone** - waifu2x-ios on iPhone 6s with iOS 11.0 GM
- **iPad** - waifu2x-ios on iPad Pro 10.5 with iOS 11.0 GM
- **PC** - waifu2x-caffe on Windows 10 16278 with [GTX 960M](https://www.geforce.com/hardware/notebook-gpus/geforce-gtx-960m)
### Results
All of the tests are running `denoise level 2` with `scale 2x` model on anime-style images from [Pixiv](https://www.pixiv.net/).

#### Test1
*Image resolution: `600*849`*

Device|Time(s)
---|---
iPhone|6.8
iPad|2.9
PC|2.1

#### Test2
*Image resolution: `3000*3328`*

Device|Time(s)
---|---
iPhone|-(\*)
iPad|49.2
PC|37.5

\* When this image is loaded on my iPhone 6s, it is automatically scaled down to 2048\*1851. The reason is unknown.

#### Evolution
*Device: iPad*
*Image resolution: `3000*3328`*

Milestone|Time(s)|RAM usage(GB)
---|---|---
Before using upconv models|141.7|1.86
After using upconv models|63.6|1.28
After adding pipeline on output|56.8|1.28
After adding pipeline on prediction|49.2|0.38

## Demo
![](screenshots/demo.png)

Image source: [https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476](https://www.pixiv.net/member_illust.php?mode=medium&illust_id=48913476)
