//
//  UITextView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-29.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public extension UITextView {
    convenience init(type: TypographyStyle,
                     text: String? =  nil,
                     color: UIColor? = nil,
                     alignment: NSTextAlignment? = nil) {
        
        self.init()

        self.text = text
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
        self.translatesAutoresizingMaskIntoConstraints = false
        // Enable font-scaling
        self.adjustsFontForContentSizeCategory = true
        let fontMetrics = UIFontMetrics(forTextStyle: type.textStyle)
        self.font = fontMetrics.scaledFont(for: type.font)
    }
}
