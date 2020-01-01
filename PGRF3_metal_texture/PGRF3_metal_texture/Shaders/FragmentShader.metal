//
//  FragmentShader.metal
//  MetalPGRF3
//
//  Created by Roman Auersvald on 14/10/2019.
//  Copyright © 2019 AuRoTech. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// vstupující vertex
struct VertexIn {
    // vypočtená pozice ve scéně
    float4 computedPosition [[position]];
    // barva
    float4 color;
    // souřadnice do textury
    float2 texCoord;
    // normála
    float3 normal;
    // velikost bodu
    float pointsize[[point_size]];
};

// hlavní metoda fs
fragment float4 basic_fragment(
                               // vstupující vertex
                               VertexIn interpolated [[stage_in]],
                               // obrázek textury
                               texture2d<float, access::sample>  tex2D [[ texture(0) ]],
                               // sampler pro texturu
                               sampler sampler2D [[ sampler(0) ]])
{
    // výpočet barvy podle souřadnic z textury
    float3 color = tex2D.sample(sampler2D, interpolated.texCoord).rgb;
    return float4(color, 1);
}