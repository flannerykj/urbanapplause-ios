//
//  StyleConstants.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public struct StyleConstants {}

public extension StyleConstants {
    static let textFieldHeight: CGFloat = 40
    static let buttonHeight: CGFloat = 50
    static let contentMargin: CGFloat = 24
    static let contentPadding: CGFloat = 16
    static let fieldSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 20
    static let tableFooterHeight: CGFloat = 32
    static let dateFormatDefault: String = "MMM d, yyyy"
    static let timeFormatDefault: String = "HH:MM:SS"
    static let defaultMarginInsets = UIEdgeInsets(top: StyleConstants.contentMargin,
                                                  left: StyleConstants.contentMargin,
                                                  bottom: StyleConstants.contentMargin,
                                                  right: StyleConstants.contentMargin)
    
    static let defaultPaddingInsets = UIEdgeInsets(top: StyleConstants.contentPadding,
                                                   left: StyleConstants.contentPadding,
                                                   bottom: StyleConstants.contentPadding,
                                                   right: StyleConstants.contentPadding)
}
