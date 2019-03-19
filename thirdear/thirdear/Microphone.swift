//
//  Microphone.swift
//  thirdear
//
//  Created by Horseman on 18/11/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import AVFoundation

class Microph {
    private var engine: AVAudioEngine?
    private var inputPlayer: AVAudioPlayerNode?
    
    init() {
        engine = AVAudioEngine()
        inputPlayer = AVAudioPlayerNode()
        
        if let engine = engine, let iplayer = inputPlayer {
            let input = engine.inputNode
            engine.attach(iplayer)
            
            let bus = 0
            let inputFormat = input.inputFormat(forBus: bus)
            engine.connect(iplayer, to: engine.mainMixerNode, format: inputFormat)
            
            input.installTap(onBus: bus, bufferSize: 512, format: inputFormat) { (buffer, time) -> Void in
                iplayer.scheduleBuffer(buffer)
            }
        }
    }
    
    func monitor(interval: TimeInterval, completion: @escaping ()->()) {
        // звук с микрофона
        guard let engine = engine, let iplayer = inputPlayer else { return }
        try! engine.start()
        iplayer.play()
        
        _ = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            iplayer.stop()
            engine.stop()
            completion()
        }
    }
}
