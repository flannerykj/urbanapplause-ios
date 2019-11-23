//
//  UILabel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    convenience init(type: TypographyStyle,
                     text: String? =  nil,
                     color: UIColor? = nil,
                     alignment: NSTextAlignment? = nil) {
        
        self.init()

        self.text = text
        numberOfLines = 0
        self.style(as: type)
        if let color = color {
            self.textColor = color
        }
        if let alignment = alignment {
            self.textAlignment = alignment
        }
    }

    func style(as type: TypographyStyle) {
        
        self.textColor = type.color
        self.clipsToBounds = false
        self.setContentCompressionResistancePriority(.required, for: .vertical)

        self.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.translatesAutoresizingMaskIntoConstraints = false
        self.baselineAdjustment = .none
        self.adjustsFontForContentSizeCategory = true
        if let font = UIFont(name: type.fontName, size: type.fontSize) {
            let fontMetrics = UIFontMetrics(forTextStyle: type.textStyle)
            self.font = fontMetrics.scaledFont(for: font)
        }
    }
}
