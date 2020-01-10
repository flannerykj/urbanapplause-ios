//
//  NSMutableAttributedString.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public extension NSMutableAttributedString {
    func style(as typographyStyle: TypographyStyle, withLink link: String? = nil, for range: NSRange? = nil) {
        let _range = range ?? NSRange(location: 0, length: self.string.count)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        self.addAttributes([
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: typographyStyle.font,
            NSAttributedString.Key.foregroundColor: typographyStyle.color
        ], range: _range)
        
        if let linkText = link {
            self.addAttributes([
                NSAttributedString.Key.link: linkText
            ], range: _range)
        }
    }
}
