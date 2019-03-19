//
//  SoundPlayer.swift
//  LoseMeNot
//
//  Created by Horseman on 06/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation
import AVFoundation

class SoundPlayer{
    private var session: AVAudioSession!
    private var player = AVAudioPlayer()
    private var prepared = false
    private var filename = ""
    
    init(_ session: AVAudioSession) {
        self.session = session
    }
    
    private func initPlayer() {
        prepared = false
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            prepared = player.prepareToPlay()
        } catch {
            print("Player alarm sound failed. Reason:\(error)")
        }
    }
    
    func setSound(_ filename: String) {
        self.filename = filename
        initPlayer()
    }
    
    func play() {
        if prepared {
            player.play()
        }
    }
    
    func stop() {
        if prepared, player.isPlaying {
            player.stop()
        }
    }
    
    func loop(_ loops: Int) {
        if prepared {
            player.numberOfLoops = loops
            player.play()
        }
    }
}
