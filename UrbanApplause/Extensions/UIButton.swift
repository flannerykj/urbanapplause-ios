//
//  UIButton.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {

    func style(as style: ButtonStyle) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = style.backgroundColor
        layer.cornerRadius = style.cornerRadius
        setTitleColor(style.defaultTextColor, for: .normal)
        setTitleColor(style.activeTextColor, for: .focused)
        titleLabel?.style(as: style.typography)
        if let height = style.height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        contentEdgeInsets = style.contentEdgeInsets
        imageEdgeInsets = style.imageEdgeInsets
        if let borderColor = style.borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1
        }
        switch style {
        case .icon(_, let size):
            if let img = style.image {
                setImage(img, for: .normal)
            }
            let size = size ?? 30
            imageView?.frame = CGRect(x: 0, y: 0, width: size, height: size)
            imageView?.contentMode = .scaleAspectFit
            
            widthAnchor.constraint(equalToConstant: size).isActive = true
            setContentCompressionResistancePriority(UILayoutPriority.defaultHigh,
                                                    for: NSLayoutConstraint.Axis.horizontal)
        default:
            break
        }
    }
    
    func enable() {
        isEnabled = true
        alpha = 1.0
    }
    func disable() {
        isEnabled = false
        alpha = 0.5
    }
    
    func pinSidesto(view: UIView) {
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.rightAnchor.constraint(equalTo: view.rightAnchor)
            ])
    }
}
