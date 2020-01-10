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
