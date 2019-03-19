//
//  SoundObserver.swift
//  LoseMeNot
//
//  Created by Horseman on 06/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation
import AVFoundation

enum SoundObserverError: Error {
    case noAccessToMicrofone
    case UnableToStartSession
    case UnableToStopSession
}

class SoundObserver {
    private var session: AVAudioSession!
    private var recorder: AVAudioRecorder!
    private var listener: AppObserver?
    
    private var peakTimer: Timer!
    
    private(set) var isActive = false
    private var prepared = false
    private var permissionGranted = false
    
    var peakLevel: Float = -1.0
    
    init(_ session: AVAudioSession) {
        self.session = session
    }
    
    func start(listener: AppObserver) {
        self.listener = listener
        
        do {
            if (!prepared) {try prepare()}            
            
            recorder.prepareToRecord()
            isActive = recorder.record()
            startTimer()
        } catch {
            print("Sorry! Can't start session: \(error).")
        }
    }
    
    func stop() {
        stopTimer()
        recorder.stop()        
        listener = nil
    }
    
    func grantRecord(_ grant: Bool) {
        permissionGranted = grant
    }
    
    private func prepare () throws {
        try checkPermissions()
        try initSession()
        try initRecorder()
        
        prepared = true
    }
    
    private func checkPermissions () throws {
//        //есть тут проблемы с асинхроностью при проверке доступа к микрофону...
//        session.requestRecordPermission() { [unowned self] allowed in
//            if allowed {
//                self.permissionGranted = true
//            } else {
//                self.permissionGranted = false
//            }
//        }
        if (!permissionGranted) {throw SoundObserverError.noAccessToMicrofone}
    }
    
    private func initSession() throws {
        // подписываемся на события
        registerSessionHandlers()
        
        // использоавть микрофон телефона всегда
        setDefaultInput()
    }

    private func initRecorder() throws {
        let file = File.getTempFile() // че то смщущает, что у нас запись в файл ведется... а если 10-12 часов, он какого размера будет? Думаю ,тут уместна запись/перезапись в память.
        print(file)
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100, //мне кажется битрейт можно меньше сделать, нам же не качество важно, а громкость
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try AVAudioRecorder(url: file, settings: settings)
        recorder.isMeteringEnabled = true
    }
    
    func registerSessionHandlers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: AVAudioSession.sharedInstance())
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }
    
    @objc func handleInterruption(_ notification: Notification) {
        //определим тип
        guard let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        
        guard let recorder = recorder else { return }
        // начало
        if type == .began {
            // морозим
            recorder.pause()
        }
            // окончание
        else if type == .ended {
            // возобновляем мониторинг
            recorder.record()
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification) {
        setDefaultInput()
    }
    
    func setDefaultInput() {
        if let mic = session.availableInputs?.first(where: { (mic) -> Bool in
            return mic.portType == AVAudioSession.Port.builtInMic }) {
            do {
                try session.setPreferredInput(mic)
            } catch {
                print("Set build in mic as defualt input failed. Reason: \(error)")
            }
        }
        
        do {
            try session.overrideOutputAudioPort(.speaker)
        } catch {
            print("Override output audio to default speacker failed. Reason: \(error)")
        }
    }
    
    private func peak()-> Float {
        recorder.updateMeters()
        return recorder.peakPower(forChannel: 0)
    }
    
    private func startTimer() {
        peakTimer =
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkLevel(_:)), userInfo: nil, repeats: true)
    }
    
    private func stopTimer() {
        if peakTimer != nil {
            peakTimer.invalidate()
        }
    }
    
    @objc func checkLevel(_: Timer) {
        let level = peak()
        print("Listerning check level: \(level)")
        if level > peakLevel {
            stopTimer()
            listener?.alarm()
        }
    }
}
