//
//  ViewController.swift
//  PGRF_metal_texture
//
//  Created by Roman Auersvald on 29/12/2019.
//  Copyright © 2019 Default. All rights reserved.
//

import Cocoa
import MetalKit


struct SceneMatricesfloat4x4 {
    var projectionMatrix: float4x4 = float4x4()
    var modelviewMatrix: float4x4 = float4x4()
}

class ViewController: NSViewController, MTKViewDelegate, NSWindowDelegate {
    
    // volaná delegátní mrtoda při změně velikosti obrazovky
    func windowDidResize(_ notification: Notification) {
        self.metalView.frame = self.view.frame
    }
    
    // delegátní metoda volaná při změně framu metal view - přizpůsobení scény novému oknu
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0),
                                                                  aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height),
                                                                  nearZ: 0.01, farZ: 100.0)
    }
    
    // volané delegátní metodou MTKViewDelegate - pro renderování, volá dále naši metodu render
    func draw(in view: MTKView) {
        autoreleasepool {
            self.render()
        }
    }
    
    
    /// direct access to GPU
    var device: MTLDevice!
    /// nastavení pipeline - formáty barev etc.
    var pipelineState: MTLRenderPipelineState!
    /// commands to be executed on GPU
    var commandQueue: MTLCommandQueue!
    /// projekční matice
    var projectionMatrix : float4x4 = float4x4()
    /// světová modelová matice
    var worldModelMatrix : float4x4 = float4x4()
    /// to, kam se vykresluje scéna "canvas"
    let metalView = MTKView()
    /// pole vrcholů objektu
    var vertexBuffer = [Vertex]()
    /// pole indexů vrcholů pro spojení
    var indexBuffer = [UInt32]()
    /// globální matice scény
    var sceneMatrices : SceneMatricesfloat4x4!
    /// textura pro aplikaci na těleso
    var texture: MTLTexture?
    
    // volá se ihned po načtení hlavního okna
    override func viewDidLoad() {
        super.viewDidLoad()
        // vytvoření reference na aktuální zařízení
        self.device = MTLCreateSystemDefaultDevice()
        // vytvoření fronty příkazů
        self.commandQueue = device.makeCommandQueue()
        // načtení textury
        loadTexture()
        // naplnění matic
        setupMatrices()
        // nastavení vrstvy pro renderování
        setupMetalView()
        // nastavení shaderů
        setupShaders()
        // vytvoření objektu
        createPrimitives()
    }
    
    /// načte texturu ze souboru umístěném v root adresáři
    private func loadTexture(){
        let textureLoader = MTKTextureLoader.init(device: self.device)
        guard let path = Bundle.main.path(forResource: "textura", ofType: "jpg") else {return}
        let data = NSData(contentsOfFile: path)! as Data
        
        self.texture = try! textureLoader.newTexture(data: data, options: [MTKTextureLoader.Option.SRGB : (false as NSNumber)])
    }
    
    /// nastaví projekční a modelovou matici
    private func setupMatrices(){
        self.sceneMatrices = SceneMatricesfloat4x4()
        
        projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)
        
        worldModelMatrix = float4x4()
        worldModelMatrix.translate(0.0, y: 0.0, z: 4)
        worldModelMatrix.rotateAroundX(float4x4.degrees(toRad: 0), y: 0.0, z: 0.0)
        
        sceneMatrices.modelviewMatrix = worldModelMatrix
        sceneMatrices.projectionMatrix = projectionMatrix
    }
    
    /// vytvoření vzorového trojúhelníku - vb a ib
    private func createPrimitives(){
        let vertCol1 = simd_float4.init(1, 0, 0, 1)
        let vertCol2 = simd_float4.init(0, 1, 0, 1)
        let vertCol3 = simd_float4.init(0, 0, 1, 1)
        
        self.vertexBuffer.append(Vertex(position: simd_float3.init(0, 0, -2), color: vertCol1, normal: simd_float3.init(0.0,1.0,0.0), texcord: simd_float2.init(0, 0)))
        
        self.vertexBuffer.append(Vertex(position: simd_float3.init(0, 0.5, -2), color: vertCol2, normal: simd_float3.init(0.0,1.0,0.0), texcord: simd_float2.init(0.0, 0.5)))
        
        self.vertexBuffer.append(Vertex(position: simd_float3.init(1, 1, -2), color: vertCol3, normal: simd_float3.init(0.0,1.0,0.0), texcord: simd_float2.init(1, 1)))
        
        self.indexBuffer.append(0)
        self.indexBuffer.append(2)
        self.indexBuffer.append(1)
    }
    
    // přidání metalView do hierarchie, nastavení delegáta
    private func setupMetalView(){
        metalView.device = self.device
        metalView.clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)
        metalView.delegate = self
        metalView.framebufferOnly = false
        metalView.frame = self.view.frame
        self.view.addSubview(metalView)
    }
    
    private func render(){
        // aktuální snímek, do kterého se bude kreslit
        guard let drawable = self.metalView.currentDrawable else {return}
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        if let renderPassDescriptor = self.metalView.currentRenderPassDescriptor{
            // pozadí smínku
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.63, 0.81, 1.0, 1.0)
            
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            // obecné nastavení render encoderu
            renderEncoder.setFrontFacing(.counterClockwise)
            renderEncoder.setCullMode(.back)
            renderEncoder.setRenderPipelineState(self.pipelineState)
            
            // výpočet velikosti pro matice v paměti
            let uniformBufferSize = MemoryLayout<SceneMatricesfloat4x4>.size(ofValue: sceneMatrices) + 4
            // vytvoření bufferu s maticemi o velikosti vypočtené v předchozím kroku
            let uniformBuffer = device.makeBuffer(
                bytes: &sceneMatrices,
                length: uniformBufferSize,
                options: .storageModeShared)
            // scene matrices pro vertex shader
            renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            
            if self.texture != nil{
                // nastavení textury
                renderEncoder.setFragmentTexture(texture!, index: 0)
            }
            
            let samplerState = buildSamplerState(device: self.device)
            renderEncoder.setFragmentSamplerState(samplerState, index: 0)
            // výpočet velikosti vertex bufferu
            let vbDataSize = self.vertexBuffer.count * MemoryLayout.size(ofValue: self.vertexBuffer[0])
            // vytvoření vb
            guard let vertexBuffer = device.makeBuffer(bytes: self.vertexBuffer, length: vbDataSize, options: .storageModeShared) else {return}
            // výpočet velikosti ib
            let ibDataSize = self.vertexBuffer.count * MemoryLayout.size(ofValue: self.indexBuffer[0])
            // vytvoření ib
            guard let indexBuffer = device.makeBuffer(bytes: self.indexBuffer, length: ibDataSize, options: .storageModeShared) else {return}
            // přiřazení vb do render encoderu - pro vs
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            // kreslení trojůhelníku
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: 3, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
            
            // konec kódování aktuálního snímku
            renderEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    // nastavení shaderů
    private func setupShaders(){
        
        let defaultLibrary = device.makeDefaultLibrary()!
        // inicializace fs a jeho hlavní metody
        let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
        // inicializace vs a jeho hlavní metody
        let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")
        
        self.metalView.colorPixelFormat = .bgra8Unorm_srgb
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperation.add;
        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperation.add;
        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactor.one;
        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactor.one;
        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactor.oneMinusSourceAlpha;
        
        // kompilace pipeline do pipeline state
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
    }
    
    // specifikace a vytvoření sampler state pro vzorkování textury v fs
    private func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
}

