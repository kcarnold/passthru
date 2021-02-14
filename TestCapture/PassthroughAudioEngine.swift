//
//  AudioSource.swift
//  TestCapture
//
//  Created by ka37 on 1/23/21.
//

import Foundation
import AVFoundation

class PassthroughAudioEngine {
    private let inputEngine = AVAudioEngine()
    private let outputEngine = AVAudioEngine()
    var outputFormat: AVAudioFormat;

    init() {
        outputFormat = outputEngine.outputNode.outputFormat(forBus: 0)
        
//        masterBuffer = AVAudioPCMBuffer(
//            pcmFormat: outputFormat, frameCapacity: 44100
//        )!
    }
    
    func prepare() {
        let frequency: Float = 440
        let amplitude: Float = 0.5

        let twoPi = 2 * Float.pi

        let mainMixer = outputEngine.mainMixerNode
        let output = outputEngine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate)
        // Use output format for input but reduce channel count to 1

        var currentPhase: Float = 0
        // The interval by which we advance the phase each frame.
        let phaseIncrement = (twoPi / sampleRate) * frequency

        let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                // Advance the phase for the next frame.
                currentPhase += phaseIncrement
                if currentPhase >= twoPi {
                    currentPhase -= twoPi
                }
                if currentPhase < 0.0 {
                    currentPhase += twoPi
                }
                // Set the same value on all channels (due to the inputFormat we have only 1 channel though).
                for (i, buffer) in ablPointer.enumerated() {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = sin(Float(frame) * phaseIncrement * Float(i + 1)) * amplitude
                }
            }
            return noErr
        }

        outputEngine.attach(srcNode)

        outputEngine.connect(srcNode, to: mainMixer, format: outputFormat)
        outputEngine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 0.5
    }

/*
class PassthroughAudioEngine {
    
    var masterBuffer: AVAudioPCMBuffer;
    
    fileprivate func prepareInputEngine() {
        inputEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputEngine.inputNode.inputFormat(forBus: 0)) {
            buffer, when in
            let bufferSize = buffer.frameLength
            var power = Float(0.0);
            let channelCount = Int(buffer.format.channelCount);
            
            for channel in 0..<channelCount {
                let srcData = buffer.floatChannelData![channel]
                let tgtData = self.masterBuffer.floatChannelData![channel]
                for frame in 0..<Int(buffer.frameLength) {
                    tgtData[frame] = srcData[frame]
                    power += pow(srcData[frame], 2)
                }
            }
            self.masterBuffer.frameLength = buffer.frameLength
            print("Input buffer! \(channelCount) \(bufferSize) \(when.isHostTimeValid) \(power / Float(bufferSize))")
        }
        
        inputEngine.prepare()
    }
    
    func prepare() {
        
        //prepareInputEngine()
        
        let phaseIncrement = 2 * Float.pi / Float(outputFormat.sampleRate) * 440;
        
        let playerNode = AVAudioSourceNode { (silence, timeStamp, frameCount, audioBufferList) -> OSStatus in
            let audioBufferListPtr = UnsafeMutableAudioBufferListPointer(audioBufferList)
            print("Output buffer! \(frameCount) \(audioBufferListPtr.count)")

//            let masterBufferMut = UnsafeMutableAudioBufferListPointer(self.masterBuffer.mutableAudioBufferList)

            for (i, outBufferChannel) in audioBufferListPtr.enumerated() {
//            for (masterBufferChannel, outBufferChannel) in zip(masterBufferMut, audioBufferListPtr) {
//                let masterBufferPtr = UnsafeMutableBufferPointer<Float>(masterBufferChannel)
                let outBufferPtr = UnsafeMutableBufferPointer<Float>(outBufferChannel)
                for frame in 0..<Int(frameCount) {
                    var sample = sin(Float(frame) * phaseIncrement)//Float(0);
//                    if (frame < self.masterBuffer.frameLength) {
//                        sample = masterBufferPtr[frame]
//                    }
                    outBufferPtr[frame] = sample
                }
            }
            return noErr
        }

        outputEngine.attach(playerNode)
        outputEngine.connect(playerNode, to: outputEngine.mainMixerNode, format: outputFormat)
        outputEngine.connect(outputEngine.mainMixerNode, to: outputEngine.outputNode, format: outputFormat)
        outputEngine.mainMixerNode.outputVolume = 1.0

        outputEngine.prepare()
    }
*/
    func start() throws {
//        try inputEngine.start()
        try outputEngine.start()
    }
}
