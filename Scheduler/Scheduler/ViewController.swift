//
//  ViewController.swift
//  Scheduler
//
//  Created by Horseman on 28/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import UIKit
import CoreLocation

enum AppState {
    case Off    // не работает
    case Auto   // Авто режим
    case Listen // режим Обнаружения
    case Alarm  // режим Отклика
    case Sleep  // режим Сна
}


class ViewController: UIViewController {
    
    var startStateTime = Date()
    let interval = TimeInterval(5)
    var State = AppState.Off
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestAlwaysAuthorization()
        manager.startMonitoringVisits()
        manager.delegate = self
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        start()
    }
    
    func start() {
        // начинаем с Auto
        State = AppState.Auto
        startStateTime = Date()
     
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    func checkState() {
        if startStateTime.addingTimeInterval(interval)<Date() {
            switch State {
            case AppState.Auto:
                State = AppState.Listen
                startStateTime = Date()
            case AppState.Listen:
                State = AppState.Alarm
                startStateTime = Date()
            case AppState.Alarm:
                State = AppState.Auto
                startStateTime = Date()
            default:
                State = AppState.Auto
            }
        }
        
        switch UIApplication.shared.applicationState {
        case .active:
            print("App is active. Current State = \(State) - \(Date())")
        case .background:
            print("App is backgrounded. Current State = \(State) - \(Date())")
        case .inactive:
            break
        }
    }

}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        checkState()

    }

}
