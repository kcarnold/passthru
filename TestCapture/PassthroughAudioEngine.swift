//
//  AudioSource.swift
//  TestCapture
//
//  Created by ka37 on 1/23/21.
//

import Foundation
import AVFoundation
//import CTPCircularBuffer

class PassthroughAudioEngine {
    private let inputEngine = AVAudioEngine()
    private let outputEngine = AVAudioEngine()

    var circularBuffer: TPCircularBuffer

    var outputFormat: AVAudioFormat
    var currentPhase: Float
    var amplitude: Float
    
    init() {
        outputFormat = outputEngine.outputNode.outputFormat(forBus: 0)
        
        currentPhase = 0.0
        amplitude = 0.0
        
        circularBuffer = TPCircularBuffer()
        _TPCircularBufferInit(&circularBuffer, 480000, MemoryLayout<TPCircularBuffer>.size)
    }
    
    fileprivate func prepareInputEngine() {
        inputEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: outputFormat) {
            buffer, when in
            let bufferSize = buffer.frameLength
            var power = Float(0.0);
            let channelCount = Int(buffer.format.channelCount);

            var timestamp = when.audioTimeStamp

            // FIXME: When the source is mono, this fails because it tries to pull out two channels.
            // Maybe duplicate the mono data in that case?
            // Workaround: request outputFormat instead of inputFormat.
            TPCircularBufferCopyAudioBufferList(&self.circularBuffer, buffer.audioBufferList, &timestamp, kTPCircularBufferCopyAll, buffer.format.streamDescription)
            
            for channel in 0..<channelCount {
                let srcData = buffer.floatChannelData![channel]
                for frame in 0..<Int(buffer.frameLength) {
                    power += pow(srcData[frame], 2)
                }
            }
            print("Input buffer! \(channelCount) \(bufferSize) \(when.isHostTimeValid) \(power / Float(bufferSize))")
            self.amplitude = 0.5//power * 1
        }
        
        inputEngine.prepare()
    }
    
    func prepare() {
        prepareInputEngine()
        
        let mainMixer = outputEngine.mainMixerNode
        let output = outputEngine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
//        let sampleRate = Float(outputFormat.sampleRate)

        let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let audioBufferListPtr = UnsafeMutableAudioBufferListPointer(audioBufferList)
            print("Output buffer! \(frameCount) \(audioBufferListPtr.count)")

            let samplesInBuffer = TPCircularBufferPeek(&self.circularBuffer, nil, outputFormat.streamDescription)
            
            //TPCircularBufferConsumeNextBufferListPartial(&self.leftBuffer, UInt32(audioBufferListPtr.count), outputFormat.streamDescription)
            var ioLengthInFrames = UInt32(frameCount)
            var outTimestamp = AudioTimeStamp()
            TPCircularBufferDequeueBufferListFrames(&self.circularBuffer, &ioLengthInFrames, audioBufferList, &outTimestamp, outputFormat.streamDescription)
            print("samples: \(samplesInBuffer) consumed \(ioLengthInFrames)")

            return noErr
        }

        outputEngine.attach(srcNode)

        outputEngine.connect(srcNode, to: mainMixer, format: outputFormat)
        outputEngine.connect(mainMixer, to: output, format: outputFormat)
        mainMixer.outputVolume = 0.5
        
        outputEngine.prepare()
    }

    func start() throws {
        try inputEngine.start()
        try outputEngine.start()
    }
}
