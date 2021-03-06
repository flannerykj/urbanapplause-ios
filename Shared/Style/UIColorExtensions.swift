//
//  UIColorExtensions.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public extension UIColor {
    static var borderColor = UIColor.systemGray
    static var placeholderText = UIColor.systemGray
    static var success = UIColor.systemGreen
    static var warning = UIColor.systemYellow
    static var error = UIColor.systemRed
    static var backgroundAccent = UIColor.white.withDarkModeOption(.black)
    static var customTextColor = UIColor.darkText.withDarkModeOption(.lightText)
}
public extension UIColor {
    func withDarkModeOption(_ darkModeColor: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (traitCollection: UITraitCollection) -> UIColor in
                if traitCollection.userInterfaceStyle == .dark {
                    return darkModeColor
                } else {
                    return self
                }
            }
        } else {
            return darkModeColor
        }
    }
    
    public convenience init(hexString: String) {
        let red, green, blue, alpha: CGFloat

        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    red = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    alpha = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: red, green: green, blue: blue, alpha: alpha)
                    return
                }
            }
        }
        self.init(red: 1, green: 1, blue: 1, alpha: 1)
    }
}
