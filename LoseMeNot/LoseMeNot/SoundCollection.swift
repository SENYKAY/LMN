//
//  SoundCollection.swift
//  LoseMeNot
//
//  Created by Horseman on 06/12/2018.
//  Copyright © 2018 ITSln. All rights reserved.
//

import Foundation

private struct Sound {
    var name: String
    var filename: String
    
    init(name: String, filename: String) {
        self.name = name
        self.filename = filename
    }
    
    init(name: String) {
        self.init(name: name, filename: name)
    }    
}

class SoundCollection {
    private var list = [Sound]()
    
    init() {
        list.append(Sound.init(name: "uuu", filename: "uuu"))   // default
        list.append(Sound.init(name: "aaaaa", filename: "aaaaa"))
        list.append(Sound.init(name: "ambul", filename: "ambul"))
        list.append(Sound.init(name: "atass", filename: "atass"))
        list.append(Sound.init(name: "dramm", filename: "dramm"))
        list.append(Sound.init(name: "duet", filename: "duet"))
        list.append(Sound.init(name: "fafa", filename: "fafa"))
        list.append(Sound.init(name: "ffaffa", filename: "ffaffa"))
        list.append(Sound.init(name: "gai", filename: "gai"))
        list.append(Sound.init(name: "grazhdan", filename: "grazhdan"))
        list.append(Sound.init(name: "gudok", filename: "gudok"))
        list.append(Sound.init(name: "gus", filename: "gus"))
        list.append(Sound.init(name: "italia", filename: "italia"))
        list.append(Sound.init(name: "metall", filename: "metall"))
        list.append(Sound.init(name: "pechal", filename: "pechal"))
        list.append(Sound.init(name: "specsig", filename: "specsig"))
        list.append(Sound.init(name: "svist", filename: "svist"))
        list.append(Sound.init(name: "train", filename: "train"))
        list.append(Sound.init(name: "trell", filename: "trell"))
        list.append(Sound.init(name: "vozduh", filename: "vozduh"))
        
    }
    
    func getCount() -> Int {
        return list.count
    }
    
    func getName(_ idx: Int) -> String {
        return list[idx].name
    }
    
    func getFileName(_ idx: Int) -> String {
        return list[idx].filename
    }
    
}
