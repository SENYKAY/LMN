//
//  ViewController.swift
//  thirdear
//
//  Created by Horseman on 29/10/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController, AVAudioRecorderDelegate, Observer {
    let defaults = UserDefaults.standard
    lazy var recorder = Recorder()
    var levelTimer: Timer!
    
    
    @IBOutlet weak var currentLevel: UILabel!
    @IBOutlet weak var infoText: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    
    let LEVEL_MIN: Float = -30.0
    let LEVEL_MAX: Float = 10.0
    var LEVEL_NOISE: Float = 0.0
    
    
    fileprivate func initLevel() {
        levelSlider.minimumValue = LEVEL_MIN
        levelSlider.maximumValue = LEVEL_MAX
        
        let level = defaults.float(forKey: "LEVEL_NOISE")
        levelSlider.value = level
        setLevel()
    }
    
    fileprivate func setLevel() {
        LEVEL_NOISE = levelSlider.value
        
        defaults.set(LEVEL_NOISE, forKey: "LEVEL_NOISE")
        currentLevel.text = String(format:"%.2f db", LEVEL_NOISE)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLevel()
    }
    
    func info(text: String) {
        infoText.textColor = UIColor.red
        infoText.text = text
    }
    
    fileprivate func stopTimer() {
        if levelTimer != nil {
            levelTimer.invalidate()
        }
    }
    
    fileprivate func stop() {
        do {
            stopTimer()
            try recorder.stop()
            startButton.setTitle("START", for: UIControl.State.normal)
        } catch {
            print("Unexpected error: \(error).")
            
        }
    }
    
    fileprivate func startTimer() {
        levelTimer =
            Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(refreshLevel(_:)), userInfo: nil, repeats: true)
    }
    
    fileprivate func start()  {
        do {
            try recorder.start(observer: self)
            startButton.setTitle("STOP", for: UIControl.State.normal)
            startTimer()
        } catch {
            info(text: "Sorry! Can't start session: \(error).")
        }
    }
    
    func update() {
        // изменилось состояние рекордера
        
        if (recorder.isActive) {
            if (!recorder.outputHeadphones) {
                stop()
                info(text: "Sorry! Can't start without headphones. Plug in headphones and try to start again.")
            }
        }
    }
    
    @objc func refreshLevel(_: Timer) {
        let level = recorder.peak()
        Log.info(text: "current level \(level) margin \(LEVEL_NOISE)")
        if level > LEVEL_NOISE {
            info(text: "Get alarm level = " + String(level))
            stopTimer()
            Log.info(text: "PEAK level \(level) margin \(LEVEL_NOISE)")
            recorder.alarm { self.startTimer() }
        }
        else {
            info(text:"")
        }
    }
    
    @IBAction func start(_ sender: Any) {
        if (recorder.isActive) {
            stop()
            share()
        } else {
            start()
        }
    }
    
    @IBOutlet weak var levelSlider: UISlider!
    @IBAction func changeLevel(_ sender: Any) {
        setLevel()
    }

    func share() {
        let objectsToShare = [File.getTempFile()]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }

}

