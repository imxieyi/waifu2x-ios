# waifu2x on iOS
[![](https://img.shields.io/itunes/v/1286485858.svg)](https://itunes.apple.com/app/waifu2x/id1286485858)
[![](https://img.shields.io/github/license/imxieyi/waifu2x-ios.svg)](https://github.com/imxieyi/waifu2x-ios/blob/master/LICENSE)

[![](assets/appstore.svg)](https://itunes.apple.com/app/waifu2x/id1286485858)
[![](assets/macappstore.svg)](https://apps.apple.com/us/app/id1479332784)

## Introduction
This is a [Core ML](https://developer.apple.com/documentation/coreml) implementation of [waifu2x](https://github.com/nagadomi/waifu2x). The target of this project is to run waifu2x models right on iOS devices even without network. For macOS version please refer to [waifu2x-mac](https://github.com/imxieyi/waifu2x-mac).

Video support based on [Metal Performance Shaders](https://developer.apple.com/documentation/metalperformanceshaders) is also included in this repo. Models are loaded directly from Core ML models (see [CoreML-MPS](https://github.com/imxieyi/waifu2x-ios/tree/master/CoreML-MPS)). It is meant to be run on macOS with a powerful discerete GPU through [Mac Catalyst](https://developer.apple.com/mac-catalyst/). Running it on iOS devices will significantly drop battery life and cause thermal issues. Most likely it will crash immediately.

**The author is not responsible of any damage to your device.**

## Requirements
 - XCode 9+
 - iOS 11+
 - macOS 10.15+ (for Mac Catalyst)
 
## Usage
After cloning this repo, remember to update submodules:

```bash
git submodule update --init
```

Then open `waifu2x-ios.xcworkspace` (not `waifu2x-ios.xcodeproj`).

Click `Video Test` on the top to pick video files. Output path will be printed in the console (starts with `Output path:`).
 
## Image format
Images with `RGB` color space works fine. Others should be converted to `RGB` before processing otherwise output image will be broken.
Alpha channel is scaled using [bicubic interpolation](https://en.wikipedia.org/wiki/Bicubic_interpolation). Generally it runs on GPU. It automatically falls back to CPU if image is too large for Metal to process, which is extremely slow. (A bad idea)

## Video format
The built-in video decoder on iOS and macOS is very limited. If your video doesn't work, you can convert to a supported format using [ffmpeg](https://ffmpeg.org/):

```bash
ffmpeg -i <INPUT VIDEO> -c:v libx264 -preset ultrafast -pix_fmt yuv420p -c:a aac -f mp4 <OUTPUT VIDEO>.mp4
```

## About models
This repository includes all the models converted from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe). **If you want to dig into Core ML, it is recommended that you should convert them by yourself.**

You can [convert pre-trained models to Core ML format](https://developer.apple.com/documentation/coreml/converting_trained_models_to_core_ml) and then import them to **XCode**. The pre-trained model can be obtained from [waifu2x-caffe](https://github.com/lltcggie/waifu2x-caffe).

You can use the same method described in [MobileNet-CoreML](https://github.com/hollance/MobileNet-CoreML). **You should not specify any input and output layer in python script.**

**A working model should have input and output like the following example:**

![](screenshots/model_example.png)

## Benchmark on images
### Environment
- **iPhone6s** - waifu2x-ios on iPhone 6s with iOS 11.1
- **iPhone8** - waifu2x-ios on iPhone 8 with iOS 11.0
- **iPhone11Pro** - waifu2x-ios on iPhone 11 Pro with iOS 13.1
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
iPhone11Pro|2.0
iPad|2.9
PC|2.1

#### Test2
*Image resolution: `3000*3328`*

Device|Time(s)
---|---
iPhone6s|129.2
iPhone8|73.5
iPhone11Pro|18.8
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

## Performance on video
About 1.78 frames per second while scaling `1080p -> 2160p` on [5700XT](https://www.techpowerup.com/gpu-specs/radeon-rx-5700-xt.c3339) GPU.

Runs out of memory and crashes immediately with the same video on iOS with 4GB memory.

## Demo
![](screenshots/demo.png)
