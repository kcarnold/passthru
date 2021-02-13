//
//  ViewController.swift
//  TestCapture
//
//  Created by ka37 on 1/23/21.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController, AVCaptureAudioDataOutputSampleBufferDelegate {
    private let engine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: engine.inputNode.inputFormat(forBus: 0)) {
            buffer, when in
            let bufferSize = buffer.frameLength
            var power = Float(0.0);
            let channelCount = Int(buffer.format.channelCount);
            
            
            for channel in 0..<channelCount {
                let srcData = buffer.floatChannelData![channel]
                //let tgtData = masterBuffer?.floatChannelData![channel]
                for frame in 0..<Int(buffer.frameLength) {
                    //tgtData![frame] = srcData[frame]
                    power += pow(srcData[frame], 2)
                }
            }
            //masterBuffer?.frameLength = buffer.frameLength
            print("Input buffer! \(channelCount) \(bufferSize) \(when.isHostTimeValid) \(power / Float(bufferSize))")
        }
        
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

