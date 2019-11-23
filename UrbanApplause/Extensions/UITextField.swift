//
//  UITextField.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UITextField: UITextFieldDelegate {
    
    func style() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.borderColor = UIColor.borderColor.cgColor
        layer.borderWidth = 2
        borderStyle = .roundedRect
        clipsToBounds = true
        layer.cornerRadius = 30
        self.heightAnchor.constraint(equalToConstant: 64).isActive = true
        leftViewMode = .always
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 20))
    }
    
    func add(icon: UIImage?) {
        if let image = icon {
            let tintedImage = image.withRenderingMode(.alwaysTemplate) // allows re-coloring
            let iconView = UIImageView(image: tintedImage)
            iconView.tintColor = UIColor.darkGray
            leftView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 20))
            leftView?.addSubview(iconView)
            iconView.center = leftView!.center
        }
    }
    
    func setError(error: String) {
        layer.borderColor = UIColor.error.cgColor
    }
    
}
