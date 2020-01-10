//
//  Typography.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public enum TypographyStyle {
    case body, strong, h1, h2, h3, h4, h5, h6, h7, h8, label, link, small, error, placeholder
    
    public var font: UIFont {
        switch self {
        case .placeholder:
            return UIFont.italicSystemFont(ofSize: self.fontSize)
        case .h2:
            return UIFont.boldSystemFont(ofSize: self.fontSize)
        case .body:
            return UIFont.systemFont(ofSize: self.fontSize)
        default:
            return UIFont.boldSystemFont(ofSize: self.fontSize)
        }
    }
    public var attributes: [NSAttributedString.Key: Any] {
        return [NSAttributedString.Key.font: self.font]
    }
    public var textStyle: UIFont.TextStyle {
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
    
    public var fontSize: CGFloat {
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
        case .small:
            return 14
        default:
            return 17
        }
    }
    
    public var color: UIColor {
        switch self {
        case .link:
            return UIColor.systemBlue
        case .error:
            return UIColor.error
        default:
            return UIColor.systemGray
        }
    }
    
    public var height: CGFloat? {
        switch self {
        default:
            return 50
        }
    }
}
