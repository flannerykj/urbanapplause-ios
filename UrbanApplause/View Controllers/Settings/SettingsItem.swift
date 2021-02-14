//
//  SettingsItem.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-18.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

enum SettingsItem {
    case profile, createAccount, login, termsOfService, privacyPolicy, logout
    
    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .createAccount:
            return Strings.CreateAccountButtonTitle
        case .login:
            return Strings.LogInButtonTitle
        case .termsOfService:
            return Strings.TermsOfServiceLinkText
        case .privacyPolicy:
            return Strings.PrivacyPolicyLinkText
        case .logout:
            return Strings.LogOutButtonTitle
        }
    }

    var url: URL? {
        switch self {
        case .termsOfService:
            return Config.tosURL
        case .privacyPolicy:
            return Config.privacyURL
        default:
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
        case .profile, .login:
            return UIImage(systemName: "person")
        case .createAccount:
            return UIImage(systemName: "person.badge.plus")
        case .termsOfService:
            return UIImage(systemName: "doc.plaintext")
        case .privacyPolicy:
            return UIImage(systemName: "hand.raised")
        case .logout:
            return nil
        }
    }
    
    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
        case .privacyPolicy, .termsOfService, .logout:
            return .none
        default:
            return .disclosureIndicator
        }
    }
    
    var textColor: UIColor? {
        switch self {
        case .logout:
            return UIColor.systemRed
        default:
            return nil
        }
    }
}
