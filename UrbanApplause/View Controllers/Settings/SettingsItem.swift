//
//  SettingsItem.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-18.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

enum SettingsItem {
    case termsOfService, privacyPolicy, logout
    
    var title: String {
        switch self {
        case .termsOfService:
            return "Terms of Service"
        case .privacyPolicy:
            return "Privacy Policy"
        case .logout:
            return "Log out"
        }
    }

    var url: URL? {
        switch self {
        case .termsOfService:
            return Config.tosURL
        case .privacyPolicy:
            return Config.privacyURL
        case .logout:
            return nil
        }
    }
    var viewController: UIViewController? {
        switch self {
        default: return nil
        }
    }
    
    var image: UIImage? {
        switch self {
        case .termsOfService:
            return UIImage(systemName: "doc.plaintext")
        case .privacyPolicy:
            return UIImage(systemName: "hand.raised")
        case .logout:
            return UIImage(systemName: "lock")
        }
    }
}
