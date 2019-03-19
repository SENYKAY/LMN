//
//  Recorder.swift
//  thirdear
//
//  Created by Serg Boskitov on 10/11/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import AVFoundation
import os.log

enum RecorderError: Error {
    case noAccessToMicrofone
    case noHeadphonesDetected
    case UnableToStartSession
    case UnableToStopSession
}

protocol Observer{
    func update()
}

class Recorder {
    private(set) var isActive = false
    private var prepared = false
    private var permissionGranted = false
    public private(set) var outputBluetooth = false
    public private(set) var outputHeadphones = false
    
    private var recorder: AVAudioRecorder!
    private var player: AVAudioPlayer!
    private let session: AVAudioSession = AVAudioSession.sharedInstance()
    private var recObserver: Observer?
    
    private let chanel = 0
    private let alarmInterval = 1.5 // длительность сигнала

    private func prepare () throws {
        try checkPermissions()
        try initSession()
        try initRecorder()
        try initPlayer()
        
        prepared = true
    }
    
    private func checkPermissions () throws {
        //есть тут проблемы с асинхроностью при проверке доступа к микрофону...
        session.requestRecordPermission() { [unowned self] allowed in
            if allowed {
                self.permissionGranted = true
            } else {
                self.permissionGranted = false
            }
        }
        if (!permissionGranted) {throw RecorderError.noAccessToMicrofone}
    }

    private func checkHeadphones () throws {
        updatePorts()
        if !(outputHeadphones || outputBluetooth) {throw RecorderError.noHeadphonesDetected}
    }
    
    private func initSession() throws {
        try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.measurement, options:
            [
                AVAudioSession.CategoryOptions.mixWithOthers,
//                AVAudioSession.CategoryOptions.allowBluetooth,
                AVAudioSession.CategoryOptions.defaultToSpeaker
            ])
        
        // подписываемся на события
        registerSessionHandlers()
        
        // использоавть микрофон телефона всегда
        try setDefaultInput()
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
    
    private func initPlayer() throws {
        guard let url = Bundle.main.url(forResource: "Gai_Spec001", withExtension: "mp3") else { return }
        player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
    }
    
    private func setSessionActive(state: Bool) -> Bool{
        var executed = false
        let asyncExec = DispatchGroup()
        asyncExec.enter()
        DispatchQueue.global(qos: .background).async {
            defer{asyncExec.leave()}
            do {
                try self.session.setActive(state, options: .notifyOthersOnDeactivation)
                executed = true
            } catch {
                executed = false
            }
        }
        asyncExec.wait()
        return executed
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
    
    private let bluetooth = [
        AVAudioSession.Port.bluetoothA2DP,
        AVAudioSession.Port.bluetoothLE,
        AVAudioSession.Port.bluetoothHFP]

    private func updatePorts() {
        for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones  {
            outputHeadphones = true
        }
        for output in session.currentRoute.outputs where bluetooth.contains(output.portType) {
            outputBluetooth = true
        }
    }
    
    @objc func handleRouteChange(_ notification: Notification) {
        do  {
            try setDefaultInput()
        }
        catch {
            // ну нет, так нет
        }
        print("!Route changed!")
//        updatePorts()

        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                return
        }
        
        switch reason {
        case .newDeviceAvailable:
            print("New device avaible")
            for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                outputHeadphones = true
            }
        case .oldDeviceUnavailable:
            print("Some device unavaible")
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
                    outputHeadphones = false
                }
            }
        default: break
        }
        
        recObserver?.update()
    }
    
    func setDefaultInput() throws {
        if let mic = session.availableInputs?.first(where: { (mic) -> Bool in
            return mic.portType == AVAudioSession.Port.builtInMic }) {
            try session.setPreferredInput(mic)
        }
    }
    
    func start(observer: Observer) throws {
        recObserver = observer        
        if (!prepared) {try prepare()}
//        try checkHeadphones()
        if (!setSessionActive(state: true)) {throw RecorderError.UnableToStartSession}
        
        recorder.prepareToRecord()
        isActive = recorder.record()
    }
    
    func stop() throws {
        recorder.stop()
        if (!setSessionActive(state: false)) {throw RecorderError.UnableToStopSession}
        recObserver = nil
        isActive = false
    }
    
    func peak()-> Float {
        recorder.updateMeters()
        let peak = recorder.peakPower(forChannel: chanel)
        return peak
    }
    
    func alarm(completion: @escaping ()->()){
        // звук оповещения
        player.prepareToPlay()
        player.play()
        
        // ждем, пока отыграет аларм
        _ = Timer.scheduledTimer(withTimeInterval: alarmInterval, repeats: false) { _ in completion() }
    }

}
