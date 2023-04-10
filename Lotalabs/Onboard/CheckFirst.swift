//
//  CheckFirst.swift
//  Lotalabs
//
//  Created by LTS on 2021/12/12.
//

import Foundation

public class CheckFirst {
    static func isFirstTime() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isFirstTime") == nil {
            defaults.set("No", forKey:"isFirstTime")
            return true
        } else {
            return false
        }
    }
}
