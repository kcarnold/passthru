//
//  ViewController.swift
//  TestCapture
//
//  Created by ka37 on 1/23/21.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController, AVCaptureAudioDataOutputSampleBufferDelegate {
    let captureSession = AVCaptureSession()
    private let engine = AVAudioEngine()

    
    func getDevice(name: String) -> AVCaptureDevice {
        print("All devices:")
        for device in AVCaptureDevice.devices() {
            print(" - \(device.localizedName)")
        }
        for device in AVCaptureDevice.devices() {
            if (device.localizedName.lowercased() == name.lowercased()) {
                return device;
            }
        }
        print("Device \(name) not found, falling back to default.")
        return AVCaptureDevice.default(for: .audio)!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (false) {
            // Create the capture session.
            
            let globalUserInitiatedQueue = DispatchQueue.global(qos: .userInitiated)
            
            // Find the requested device
            let audioDevice = getDevice(name: "nilExternal Microphone")
            
            do {
                // Wrap the audio device in a capture device input.
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                // If the input can be added, add it to the session.
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                }
                
                let audioOutput = AVCaptureAudioDataOutput()
                
                // TODO: make a proper queue here?
                audioOutput.setSampleBufferDelegate(self, queue: globalUserInitiatedQueue)
                
                captureSession.addOutput(audioOutput)
                
                captureSession.startRunning()
            } catch {
                // Configuration failed. Handle error.
            }
        } else {
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
    }
    
    // https://stackoverflow.com/questions/33030425/capturing-volume-levels-with-avcaptureaudiodataoutputsamplebufferdelegate-in-swi
    // https://stackoverflow.com/a/41885485/69707
    func captureOutput(_            output      : AVCaptureOutput,
                       didOutput    sampleBuffer: CMSampleBuffer,
                       from         connection  : AVCaptureConnection) {

        var buffer: CMBlockBuffer? = nil

        // Needs to be initialized somehow, even if we take only the address
        let convenianceBuffer = AudioBuffer(mNumberChannels: 1, mDataByteSize: 0, mData: nil)
        var audioBufferList = AudioBufferList(mNumberBuffers: 1,
                                              mBuffers: convenianceBuffer)

        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size(ofValue: audioBufferList),
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            blockBufferOut: &buffer
        )

        let abl = UnsafeMutableAudioBufferListPointer(&audioBufferList)
        var sum:Int64 = 0
        var count:Int = 0
        var bufs:Int = 0
        for buff in abl {
            let samples = UnsafeMutableBufferPointer<Int16>(start: UnsafeMutablePointer(OpaquePointer(buff.mData)),
                                                            count: Int(buff.mDataByteSize)/MemoryLayout<Int16>.size)
            for sample in samples {
                let s = Int64(sample)
                sum = (sum + s*s)
                count += 1
            }
            bufs += 1
        }
        print( "found \(count) samples in \(bufs) buffers, RMS is \(sqrt(Float(sum)/Float(count)))" )
    }
    
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    
}

