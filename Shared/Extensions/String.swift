//
//  String.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public extension UITextInput {
    var selectedRange: NSRange? {
        guard let range = selectedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        return NSRange(location: location, length: length)
    }
}

public extension String {
    func ellipsizeCenter(maxLength: Int) -> String {
        if (maxLength >= 2) && (self.count > maxLength) {
            let index1 = self.index(self.startIndex, offsetBy: (maxLength + 1) / 2) // `+ 1` has the same effect as an int ceil
            let index2 = self.index(self.endIndex, offsetBy: maxLength / -2)

            return String(self[..<index1]) + "…\u{2060}" + String(self[index2...])
        }
        return self
    }
    
    static func pluralize(_ number: Int,
                          unit: String,
                          unitPlural: String? = nil,
                          textForZero: String? = nil) -> String {
        
        let _unitPlural = unitPlural ?? "\(unit)s"
        if number == 0 {
            return textForZero ?? "\(number) \(_unitPlural)"
        }
        if number == 1 {
            return "\(number) \(unit)"
        }
        return "\(number) \(_unitPlural)"
    }
}
