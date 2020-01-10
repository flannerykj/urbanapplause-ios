//
//  UserDefaults.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public extension UserDefaults {
    enum Key: String {
        case hasOpenedApp
    }
    
    static func getHasOpenedApp() -> Bool {
        if let hasOpenedApp = UserDefaults.standard.value(forKey: UserDefaults.Key.hasOpenedApp.rawValue) as? Bool {
            return hasOpenedApp
        }
        return false
    }

    static func setHasOpenedApp(_ hasOpened: Bool) {
        UserDefaults.standard.setValue(hasOpened,
                                       forKey: UserDefaults.Key.hasOpenedApp.rawValue)

    }
}
