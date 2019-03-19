//
//  log.swift
//  thirdear
//
//  Created by Serg Boskitov on 30/11/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import os.log

class Log {
    static var general = OSLog(subsystem: "ru.itsln.thirdear", category: "general")

    static func info(text: String) {
        os_log("%@", log: general, type: .info, text)
    }
}


