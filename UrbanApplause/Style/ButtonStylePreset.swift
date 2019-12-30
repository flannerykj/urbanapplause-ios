//
//  ButtonStyle.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-17.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit


enum ButtonStylePreset {
    var accentColor: UIColor { return .systemBlue }
    
    case primary, outlined, link, icon(name: String?, size: CGFloat?), delete, smallTag, tag
    
    var backgroundColor: UIColor {
        switch self {
        case .link, .icon:
            return UIColor.clear
        case .delete:
            return UIColor.error
        case .primary:
            return accentColor
        case .smallTag:
            return UIColor.clear
        case .outlined:
            return UIColor.clear
        default:
            return UIColor.lightGray
        }
    }
    
    var highlightedBackgroundColor: UIColor? {
        switch self {
        case .outlined:
            return accentColor.withAlphaComponent(0.5)
        default:
            return self.backgroundColor
        }
    }
    
    var typography: TypographyStyle {
        switch self {
        case .link:
            return TypographyStyle.link
        case .smallTag:
            return .small
        default:
            return TypographyStyle.label
        }
    }
    
    var height: CGFloat? {
        switch self {
        case .icon(_, let size):
            if let size = size {
                return size
            }
            return nil
        case .smallTag:
            return 24
        default:
            return 48
        }
    }
    
    var defaultTextColor: UIColor {
        switch self {
        case .primary:
            return UIColor.backgroundAccent
        default:
            return accentColor
        }
    }
    var highlightedTextColor: UIColor {
        switch self {
        case .link:
            return accentColor
        default:
            return UIColor.systemGray6
        }
    }
    var selectedTextColor: UIColor {
        switch self {
        default:
            return self.highlightedTextColor
        }
    }
    
    var selectedBackgroundColor: UIColor? {
        switch self {
        case .outlined:
            return accentColor
        default:
            return self.highlightedBackgroundColor
        }
    }
    var contentEdgeInsets: UIEdgeInsets {
        switch self {
        case .link, .icon:
            return UIEdgeInsets.zero
        case .smallTag:
            let vPadding: CGFloat = 6.0
            let hPadding: CGFloat = 8.0
            return UIEdgeInsets(top: vPadding, left: hPadding, bottom: vPadding, right: hPadding)
        default:
            return UIEdgeInsets(top: StyleConstants.contentPadding/2,
                                left: StyleConstants.contentPadding,
                                bottom: StyleConstants.contentPadding/2,
                                right: StyleConstants.contentPadding)
        }
    }
    
    var imageEdgeInsets: UIEdgeInsets {
        switch self {
        case .link, .icon:
            return UIEdgeInsets.zero
        default:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: StyleConstants.contentPadding/2)
        }
    }
    var cornerRadius: CGFloat {
        switch self {
        case .smallTag:
            return 12
        default:
            return 8
        }
    }
    var image: UIImage? {
        switch self {
        case .icon(let name, _):
            if let imageName = name {
                return UIImage(named: imageName)
            }
            return nil
        default:
            return nil
        }
    }
    var defaultBorderWidth: CGFloat {
        switch self {
        case .link:
            return 0
        default:
            return 1
        }
    }
    var defaultBorderColor: UIColor? {
        switch self {
        case .smallTag:
            return UIColor.backgroundLight
        case .outlined, .primary:
            return accentColor
        default:
            return nil
        }
    }
    var highlightedBorderColor: UIColor? {
        switch self {
        default:
            return defaultBorderColor
        }
    }
}
