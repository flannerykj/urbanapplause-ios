//
//  ShutterButton.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class ShutterButton: UIButton {

    let buttonDiameter: CGFloat = 80
    let whiteCircleDiameter: CGFloat = 60
    let whiteCircle = UIView()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.whiteCircle.backgroundColor = UIColor.systemGray6
                // self.whiteCircle.addShadow()
                self.layer.borderWidth = 4

            } else {
                self.whiteCircle.backgroundColor = UIColor.white
                // self.whiteCircle.removeShadow()
                self.layer.borderWidth = 2
            }
        }
    }

    required init() {
        super.init(frame: .zero)

        self.accessibilityIdentifier = "selfButton"
        self.translatesAutoresizingMaskIntoConstraints = false
        self.layer.cornerRadius = buttonDiameter/2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 2

        whiteCircle.translatesAutoresizingMaskIntoConstraints = false
        whiteCircle.isUserInteractionEnabled = false
        whiteCircle.accessibilityIdentifier = "shutterButton-center"
        whiteCircle.layer.cornerRadius = whiteCircleDiameter/2
        whiteCircle.backgroundColor = .white
        self.addSubview(whiteCircle)

        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: buttonDiameter),
            self.heightAnchor.constraint(equalToConstant: buttonDiameter),
            whiteCircle.heightAnchor.constraint(equalToConstant: whiteCircleDiameter),
            whiteCircle.widthAnchor.constraint(equalToConstant: whiteCircleDiameter),
            whiteCircle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            whiteCircle.centerYAnchor.constraint(equalTo: self.centerYAnchor)

            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
