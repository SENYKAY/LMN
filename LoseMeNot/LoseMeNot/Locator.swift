//
//  Locator.swift
//  LoseMeNot
//
//  Created by Horseman on 16/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation
import CoreMotion

class Locator {
    let manager = CMMotionManager()

    private var listener: AppObserver

    init(listener: AppObserver) {
        self.listener = listener
    }
    
    func start(freq: TimeInterval) {
        // стартануть проверку положения с заданным интервалом (1-2 сек)
        // при смене положения вызвать AppObserver.moved()
        
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = freq
            manager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: {(data: CMDeviceMotion?, err: Error?) in
                guard let acc = data?.userAcceleration else { return }
                
//                print("Acceleration x \(acc.x)")
//                print("Acceleration y \(acc.y)")
//                print("Acceleration z \(acc.z)")
                
                let limit = 0.1
                if acc.x.magnitude > limit || acc.y.magnitude > limit || acc.z.magnitude > limit
                {
                    self.listener.moved()
                }
            })
        }
    }
}
