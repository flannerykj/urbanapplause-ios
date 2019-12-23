//
//  UIView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    func fillWithinMargins(view: UIView) {
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            self.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            self.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            self.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
            ])
    }
    func fillWithinSafeArea(view: UIView) {
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            self.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
            self.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
    }
    
    func fill(view: UIView) {
        NSLayoutConstraint.activate([
            self.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.rightAnchor.constraint(equalTo: view.rightAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }
}
