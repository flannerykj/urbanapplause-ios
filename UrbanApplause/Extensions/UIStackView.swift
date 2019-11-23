//
//  UIStackView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UIStackView {
    func style(as type: StackViewType) {
        switch type {
        case .formWrapper:
            self.axis = .vertical
            self.spacing = StyleConstants.fieldSpacing
            self.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    func fill(from direction: GrowthDirection, relativeTo view: UIView) {
        switch direction {
        case .top:
            NSLayoutConstraint.activate([
                self.leftAnchor.constraint(equalTo: view.leftAnchor,
                                           constant: StyleConstants.contentMargin),
                
                self.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                          constant: StyleConstants.contentMargin),
                
                self.rightAnchor.constraint(equalTo: view.rightAnchor,
                                            constant: -StyleConstants.contentMargin)
                ])
        default:
            break
        }
    }
}

enum StackViewType {
    case formWrapper
}

enum GrowthDirection {
    case top, bottom, left, right
}
