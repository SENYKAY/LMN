//
//  MainObserver.swift
//  LoseMeNot
//
//  Created by Horseman on 16/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation
import AVFoundation

enum AppState {
    case Off    // не работает
    case Auto   // Авто режим
    case Listen // режим Обнаружения
    case Alarm  // режим Отклика
    case Sleep  // режим Сна
}

class MainObserver: AppObserver {
    var session: AVAudioSession!
    var observer: SoundObserver!
    var player: SoundPlayer!
    var locator: Locator!
    
    var State = AppState.Off
    private var autoDelay = TimeInterval(30*60) // после 30 минут вкл обнаружение
    private var autoStartTime = Date()
    
    struct ActiveHours {
        var start = 0
        var finish = 24
    }
    let activeHours = ActiveHours(start: 7, finish: 23)
    
    init() {
        session = initSession()
        observer = SoundObserver(session)
        player = SoundPlayer(session)
        locator = Locator(listener: self)
    }
    
    func setPermissions(_ record: Bool) {
        observer.grantRecord(record)
    }
    
    private func initSession() -> AVAudioSession {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options:
                [
                    AVAudioSession.CategoryOptions.mixWithOthers,
                    AVAudioSession.CategoryOptions.defaultToSpeaker
                ])
            if (!setSessionActive(session: session)) {throw SoundObserverError.UnableToStartSession}
        } catch {
            print("Sorry! Can't start session: \(error).")
        }
        
        return session
    }
    
    private func setSessionActive(session: AVAudioSession) -> Bool{
        var executed = false
        let asyncExec = DispatchGroup()
        asyncExec.enter()
        DispatchQueue.global(qos: .background).async {
            defer{asyncExec.leave()}
            do {
                try session.setActive(true, options: .notifyOthersOnDeactivation)
                executed = true
            } catch {
                executed = false
            }
        }
        asyncExec.wait()
        return executed
    }
    
    func start() {
        auto()
        locator.start(freq: 1.0) // раз в сек определяем движение
    }
    
    func auto() {
        State = AppState.Auto; print("State: \(State)")
        // засекли время начала
        autoStartTime = Date()
    }
    
    func check() {
        // если время сна
        if isDnd() {
            slep()
        } else
            if State != AppState.Alarm {
                if isListenTime() {
                    // переходим в режим обнаружения
                    listn()
                } else {
                    // возвращаемся в авто
                    State = AppState.Auto
                    print("Time to start listerning \(autoStartTime.addingTimeInterval(autoDelay).timeIntervalSinceNow)")
                }
            }
        
        print("State: \(State)")
    }
    
    // засыпаем
    func slep() {
        if State != AppState.Sleep {
            // сбрасываемся
            stopAction()
            // и спать
            State = AppState.Sleep;
        }
    }
    
    func listn() {
        if State != AppState.Listen {
            State = AppState.Listen;
            observer.start(listener: self)
        }
    }
    
    private func isDnd() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        
        return hour < activeHours.start || hour >= activeHours.finish
    }
    
    private func isListenTime() -> Bool {
        return autoStartTime.addingTimeInterval(autoDelay) < Date()
    }
    
    private func stopAction() {
        if State == AppState.Listen {
            // перестаем слушать
            observer.stop()
        } else if State == AppState.Alarm {
            // перестаем играть alarm
            player.stop()
        }
    }
    
    func setSound(_ sound: String) {
        player.setSound(sound)
        player.play()
    }
    
    func setDelay(_ delay: Int) {
        autoDelay = TimeInterval(delay * 60) // delay в минутах
    }
    
    // *** AppObserver ***
    func moved() {
        // сбрасываемся
        stopAction()
        // перезапускаем auto-режим
        auto()
    }
    
    func alarm() {
        observer.stop()
        State = AppState.Alarm; print("State: \(State)")
        
        // тут надо непрерывно играть аларм
//        player.loop(-1)
        
        // или
        
        // отыграли аларм и снова слушать
        player.loop(3) // 4 раза
        // ждем, пока отыграет аларм // 5 сек // и продолжаем слушать
        _ = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            // если не успели двинуть, продолжаем слушать
            if self.State == AppState.Alarm {
                self.listn()
            }
        }
    }
    
    // ***
}
