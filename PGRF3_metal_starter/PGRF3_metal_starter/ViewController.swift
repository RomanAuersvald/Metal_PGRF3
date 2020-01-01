//
//  ViewController.swift
//  PGRF_starter
//
//  Created by Roman Auersvald on 29/12/2019.
//  Copyright © 2019 Default. All rights reserved.
//

import Cocoa
import MetalKit


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

    /// pole indexů vrcholů pro spojení
    var indexBuffer = [UInt32]()

    /// textura pro aplikaci na těleso
    var texture: MTLTexture?
    
    // volá se ihned po načtení hlavního okna
    override func viewDidLoad() {
        super.viewDidLoad()
        // vytvoření reference na aktuální zařízení
        self.device = MTLCreateSystemDefaultDevice()
        // vytvoření fronty příkazů
        self.commandQueue = device.makeCommandQueue()

        // nastavení vrstvy pro renderování
        setupMetalView()

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
    
}

