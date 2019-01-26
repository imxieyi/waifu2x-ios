# waifu2x on iOS
[![](https://img.shields.io/itunes/v/1286485858.svg)](https://itunes.apple.com/app/waifu2x/id1286485858)
[![](https://img.shields.io/github/license/imxieyi/waifu2x-ios.svg)](https://github.com/imxieyi/waifu2x-ios/blob/master/LICENSE)

[![](assets/appstore.svg)](https://itunes.apple.com/app/waifu2x/id1286485858)

## Introduction
This is a [Core ML](https://developer.apple.com/documentation/coreml) implementation of [waifu2x](https://github.com/nagadomi/waifu2x). The target of this project is to run waifu2x models right on iOS devices even without network. For macOS version please refer to [waifu2x-mac](https://github.com/imxieyi/waifu2x-mac).

## Requirements
 - XCode 9+
 - iOS 11+
 
## Image format
Images with `RGB` color space works fine. Others should be converted to `RGB` before processing otherwise output image will be broken.
Alpha channel is scaled using [bicubic interpolation](https://en.wikipedia.org/wiki/Bicubic_interpolation). Generally it runs on GPU. It automatically falls back to CPU if image is too large for Metal to process, which is extremely slow. (A bad idea)
 
## About models
This repository includes all the models converted from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe). **If you want to dig into Core ML, it is recommended that you should convert them by yourself.**

You can [convert pre-trained models to Core ML format](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml) and then import them to **XCode**. The pre-trained model can be obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe).

You can use the same method described in [MobileNet-CoreML](https://github.com/hollance/MobileNet-CoreML). **You should not specify any input and output layer in python script.**

**A working model should have input and output like the following example:**

![](screenshots/model_example.png)

## Benchmark
### Environment
- **iPhone6s** - waifu2x-ios on iPhone 6s with iOS 11.1
- **iPhone8** - waifu2x-ios on iPhone 8 with iOS 11.0
- **iPad** - waifu2x-ios on iPad Pro 10.5 with iOS 11.1
- **PC** - waifu2x-caffe on Windows 10 16278 with [GTX 960M](https://www.geforce.com/hardware/notebook-gpus/geforce-gtx-960m)
### Results
All of the tests are running `denoise level 2` with `scale 2x` model on anime-style images from [Pixiv](https://www.pixiv.net/).

#### Test1
*Image resolution: `600*849`*

Device|Time(s)
---|---
iPhone6s|6.8
iPhone8|4.0
iPad|2.9
PC|2.1

#### Test2
*Image resolution: `3000*3328`*

Device|Time(s)
---|---
iPhone6s|129.2
iPhone8|73.5
iPad|49.2
PC|37.5

#### Evolution
*Device: iPad*
*Image resolution: `3000*3328`*

Milestone|Time(s)|RAM usage(GB)
---|---|---
Before using upconv models|141.7|1.86
After using upconv models|63.6|1.28
After adding pipeline on output|56.8|1.28
After adding pipeline on prediction|49.2|0.38
Pure MPSCNN implementation*|29.6|1.06

**\*: With crop size of 384 and double command buffers.**

## Demo
![](screenshots/demo.png)
