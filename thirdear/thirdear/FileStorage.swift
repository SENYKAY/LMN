//
//  FileStorage.swift
//  thirdear
//
//  Created by Horseman on 29/10/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation
import UIKit

class File {
    class func getTempDir() -> URL {
        let paths = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        return paths[0]
    }
    
    class func getTempFile() -> URL {
        return getTempDir().appendingPathComponent("tempThirdEar.m4a")
    }
    
}
