//
//  AudioSource.swift
//  TestCapture
//
//  Created by ka37 on 1/23/21.
//

import Foundation
import AVFoundation
import CTPCircularBuffer

class PassthroughAudioEngine {
    private let inputEngine = AVAudioEngine()
    private let outputEngine = AVAudioEngine()

    var leftBuffer: TPCircularBuffer
    var rightBuffer: TPCircularBuffer

    var masterBuffer: AVAudioPCMBuffer

    var outputFormat: AVAudioFormat
    var currentPhase: Float
    var amplitude: Float
    
    init() {
        outputFormat = outputEngine.outputNode.outputFormat(forBus: 0)
        
        masterBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat, frameCapacity: 44100
        )!
        
        currentPhase = 0.0
        amplitude = 0.0
        
        leftBuffer = TPCircularBuffer()
        rightBuffer = TPCircularBuffer()
        _TPCircularBufferInit(&leftBuffer, 480000, MemoryLayout<TPCircularBuffer>.size)
        _TPCircularBufferInit(&rightBuffer, 480000, MemoryLayout<TPCircularBuffer>.size)
    }
    
    fileprivate func prepareInputEngine() {
        let inputFormat = inputEngine.inputNode.inputFormat(forBus: 0)
        inputEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) {
            buffer, when in
            let bufferSize = buffer.frameLength
            var power = Float(0.0);
            let channelCount = Int(buffer.format.channelCount);

            var timestamp = when.audioTimeStamp
            
            TPCircularBufferCopyAudioBufferList(&self.leftBuffer, buffer.audioBufferList, &timestamp, kTPCircularBufferCopyAll, buffer.format.streamDescription)
//            var leftOutBuf = TPCircularBufferPrepareEmptyAudioBufferListWithAudioFormat(
//                &self.leftBuffer, self.outputFormat.streamDescription, bufferSize, &whenMut)!
//
//
//            //(&self.leftBuffer, 2, UInt32(512), nil)
//            //let tgtData = UnsafeMutableAudioBufferListPointer(leftOutBuf);
//
//            TPCircularBufferProduceAudioBufferList(&self.leftBuffer, &whenMut)
            
            for channel in 0..<channelCount {
                let srcData = buffer.floatChannelData![channel]
                //self.masterBuffer.floatChannelData![channel]
                for frame in 0..<Int(buffer.frameLength) {
//                    tgtData[frame] = srcData[frame]
                    power += pow(srcData[frame], 2)
                }
            }
            self.masterBuffer.frameLength = buffer.frameLength
            print("Input buffer! \(channelCount) \(bufferSize) \(when.isHostTimeValid) \(power / Float(bufferSize))")
            self.amplitude = 0.5//power * 1
        }
        
        inputEngine.prepare()
    }
    
    func prepare() {
        prepareInputEngine()
        
        let frequency: Float = 440
        amplitude = 0.5

        let twoPi = 2 * Float.pi

        let mainMixer = outputEngine.mainMixerNode
        let output = outputEngine.outputNode
        let outputFormat = output.inputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate)
        // Use output format for input but reduce channel count to 1

        currentPhase = 0
        // The interval by which we advance the phase each frame.
        let phaseIncrement = (twoPi / sampleRate) * frequency

        let srcNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let audioBufferListPtr = UnsafeMutableAudioBufferListPointer(audioBufferList)
            print("Output buffer! \(frameCount) \(audioBufferListPtr.count)")

            var samplesInBuffer = TPCircularBufferPeek(&self.leftBuffer, nil, outputFormat.streamDescription)
            
            //TPCircularBufferConsumeNextBufferListPartial(&self.leftBuffer, UInt32(audioBufferListPtr.count), outputFormat.streamDescription)
            var ioLengthInFrames = UInt32(frameCount)
            TPCircularBufferDequeueBufferListFrames(&self.leftBuffer, &ioLengthInFrames, nil, nil, outputFormat.streamDescription)
//            TPCircularBufferConsumeNextBufferList(&self.leftBuffer)
            print("samples: \(samplesInBuffer) consumed \(ioLengthInFrames)")

            for frame in 0..<Int(frameCount) {

                for (i, outBufferChannel) in audioBufferListPtr.enumerated() {
                    let outBuf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(outBufferChannel)
//                    let masterBuf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(masterBuffer.floatChannelData[i])
                    var sample = Float(0)
//                    if (frame < self.masterBuffer.frameLength) {
//                        sample = masterBuf[frame]
//                    }
                    sample = sin(self.currentPhase * Float(i + 1)) * self.amplitude
                    outBuf[frame] = sample
                }
            }
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
