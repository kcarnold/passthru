//
//  ViewController.swift
//  TestCapture
//
//  Created by ka37 on 1/23/21.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let engine = PassthroughAudioEngine()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        engine.prepare()
        
        do {
            try engine.start()
        } catch {
            print("Couldn't start engine: \(error)")
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

