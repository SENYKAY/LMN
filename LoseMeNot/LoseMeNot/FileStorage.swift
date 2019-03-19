//
//  FileStorage.swift
//  LoseMeNot
//
//  Created by Horseman on 06/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation

class File {
    class func getTempDir() -> URL {
        let paths = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)
        return paths[0]
    }
    
    class func getTempFile() -> URL {
        return getTempDir().appendingPathComponent("tempThirdEar.m4a")
    }
}
