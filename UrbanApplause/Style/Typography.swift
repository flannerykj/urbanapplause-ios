//
//  Typography.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-17.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

enum TypographyStyle {
    case body, strong, h1, h2, h3, h4, h5, h6, h7, h8, label, link, small, error
    
    var font: UIFont {
        return UIFont(name: self.fontName, size: self.fontSize) ?? UIFont.systemFont(ofSize: self.fontSize)
    }
    var attributes: [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.font: self.font]
    }
    var textStyle: UIFont.TextStyle {
        switch self {
        case .body:
            return .body
        case .h1:
            return UIFont.TextStyle.largeTitle
        case .h2:
            return .title1
        case .h3:
            return .title2
        case .h4:
            return UIFont.TextStyle.title3
        case .h5:
            return UIFont.TextStyle.headline
        case .h6:
            return UIFont.TextStyle.subheadline
        default:
            return .body
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .h1:
            return 32
        case .h2:
            return 26
        case .h3:
            return 24
        case .h4:
            return 22
        case .h5:
            return 20
        case .h6, .h7:
            return 18
        case .h8, .link:
            return 16
        case .small:
            return 14
        default:
            return 15
        }
    }
    
    var fontName: String {
        var style: String {
            switch self {
            case .h2:
                return Helvetica.bold.rawValue
            case .body:
                return Helvetica.normal.rawValue
            default:
                return Helvetica.bold.rawValue
            }
        }
        return style
    }
    
    var color: UIColor {
        switch self {
        case .link:
            return UIColor.systemBlue
        case .error:
            return UIColor.error
        default:
            return UIColor.systemGray
        }
    }
    
    var height: CGFloat? {
        switch self {
        default:
            return 50
        }
    }
}
