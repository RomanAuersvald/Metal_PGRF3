//
//  VertexShader.metal
//  MetalPGRF3
//
//  Created by Roman Auersvald on 14/10/2019.
//  Copyright © 2019 AuRoTech. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// vertex vstupující do vs
struct VertexIn {
    float3 position;
    float4 color;
    float3 normal;
    float2 texCoord;
};

// vertex pro fs
struct VertexOut {
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

// vstupující matice
struct SceneMatrices {
    float4x4 projectionMatrix;
    float4x4 viewModelMatrix;
};

// hlavní metoda shaderu
vertex VertexOut basic_vertex(
                              // pole vertexů vstupujících
                              const device VertexIn* vertex_array [[ buffer(0) ]],
                              // matice
                              const device SceneMatrices& scene_matrices [[ buffer(1) ]],
                              // id vertexu
                              unsigned int vid [[ vertex_id ]]) {
    
    float4x4 projectionMatrix = scene_matrices.projectionMatrix;
    
    // vytvoření výstupního vertexu a naplnění parametrů
    VertexOut outVertex = VertexOut();
    VertexIn v = vertex_array[vid];
    outVertex.computedPosition = projectionMatrix *  float4(v.position, 1.0);
    
    outVertex.normal = v.normal;
    outVertex.color = v.color;
    outVertex.texCoord = v.texCoord;
    outVertex.pointsize = 4;
    return outVertex;
}
