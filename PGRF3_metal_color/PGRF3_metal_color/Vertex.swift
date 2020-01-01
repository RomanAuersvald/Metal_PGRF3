//
//  Vertex.swift
//  
//
//  Created by Roman Auersvald on 29/12/2019.
//

import Foundation
import simd

// Vrchol tělesa
struct Vertex {
    var position : vector_float3
    var color : vector_float4
    var normal: vector_float3
    var texcord: vector_float2
}
