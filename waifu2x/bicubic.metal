//
//  bicubic.metal
//  waifu2x
//
//  Created by 谢宜 on 2018/1/23.
//  Copyright © 2018年 xieyi. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

constant float factor [[function_constant(0)]];
constant uint  inW    [[function_constant(1)]];
constant uint  inH    [[function_constant(2)]];
constant uint  outW   [[function_constant(3)]];
constant uint  outH   [[function_constant(4)]];
constant uint  outP   [[function_constant(5)]];

#define CLAMP(v, min, max) \
    if (v < min) { \
        v = min; \
    } else if (v > max) { \
        v = max; \
    }

float4 GetPixelClamped(texture2d<float, access::read> in [[texture(0)]], uint x, uint y) {
    CLAMP(x, 0, inW - 1)
    CLAMP(y, 0, inH - 1)
    return in.read(uint2(x, y));
}

// t is a value that goes from 0 to 1 to interpolate in a C1 continuous way across uniformly sampled data points.
// when t is 0, this will return B.  When t is 1, this will return C.  Inbetween values will return an interpolation
// between B and C.  A and B are used to calculate slopes at the edges.
float CubicHermite(float A, float B, float C, float D, float t) {
    float a = -A / 2.0f + (3.0f * B) / 2.0f - (3.0f * C) / 2.0f + D / 2.0f;
    float b = A - (5.0f * B) / 2.0f + 2.0f * C - D / 2.0f;
    float c = -A / 2.0f + C / 2.0f;
    float d = B;
    
    return a * t * t * t + b * t * t + c * t + d;
}

float4 SampleBicubic(texture2d<float, access::read> in [[texture(0)]], float u, float v) {
    // calculate coordinates -> also need to offset by half a pixel to keep image from shifting down and left half a pixel
    float x = u * float(inW) - 0.5;
    int xint = int(x);
    float xfract = x - floor(x);
    
    float y = v * float(inH) - 0.5;
    int yint = int(y);
    float yfract = y - floor(y);
    
    // 1st row
    auto p00 = GetPixelClamped(in, xint - 1, yint - 1);
    auto p10 = GetPixelClamped(in, xint + 0, yint - 1);
    auto p20 = GetPixelClamped(in, xint + 1, yint - 1);
    auto p30 = GetPixelClamped(in, xint + 2, yint - 1);
    
    // 2nd row
    auto p01 = GetPixelClamped(in, xint - 1, yint + 0);
    auto p11 = GetPixelClamped(in, xint + 0, yint + 0);
    auto p21 = GetPixelClamped(in, xint + 1, yint + 0);
    auto p31 = GetPixelClamped(in, xint + 2, yint + 0);
    
    // 3rd row
    auto p02 = GetPixelClamped(in, xint - 1, yint + 1);
    auto p12 = GetPixelClamped(in, xint + 0, yint + 1);
    auto p22 = GetPixelClamped(in, xint + 1, yint + 1);
    auto p32 = GetPixelClamped(in, xint + 2, yint + 1);
    
    // 4th row
    auto p03 = GetPixelClamped(in, xint - 1, yint + 2);
    auto p13 = GetPixelClamped(in, xint + 0, yint + 2);
    auto p23 = GetPixelClamped(in, xint + 1, yint + 2);
    auto p33 = GetPixelClamped(in, xint + 2, yint + 2);
    
    // interpolate bi-cubically!
    // Clamp the values since the curve can put the value below 0 or above 255
    float4 ret;
    for (int i = 0; i < 1; ++i)
    {
        float col0 = CubicHermite(p00[i], p10[i], p20[i], p30[i], xfract);
        float col1 = CubicHermite(p01[i], p11[i], p21[i], p31[i], xfract);
        float col2 = CubicHermite(p02[i], p12[i], p22[i], p32[i], xfract);
        float col3 = CubicHermite(p03[i], p13[i], p23[i], p33[i], xfract);
        float value = CubicHermite(col0, col1, col2, col3, yfract);
        CLAMP(value, 0.0f, 255.0f);
        ret[i] = value;
    }
    return ret;
    
}

kernel void BicubicSingleMain(texture2d<float, access::read> in  [[texture(0)]],
                        texture2d<float, access::write> out [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    float v = float(gid.y) / float(outH - 1);
    float u = float(gid.x) / float(outW - 1);
    out.write(SampleBicubic(in, u, v), gid);
}
