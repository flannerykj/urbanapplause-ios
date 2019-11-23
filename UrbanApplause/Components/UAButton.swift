//
//  File.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-17.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class UAButton: UIButton {
    var type: ButtonStyle
    var originalButtonText: String?
    var activityIndicator = ActivityIndicator()
    
    init(type: ButtonStyle = .link, title: String, target: Any, action: Selector, rightImage: UIImage? = nil) {
        self.type = type
        super.init(frame: .zero)
        addTarget(target, action: action, for: .touchUpInside)
        self.setTitle(title, for: .normal)
        translatesAutoresizingMaskIntoConstraints = false
        originalButtonText = title
        self.addSubview(activityIndicator)
        activityIndicator.color = type.defaultTextColor
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        activityIndicator.hidesWhenStopped = true
        style(as: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLoading() {
        originalButtonText = self.title(for: .normal)
        self.setTitle("", for: .normal)
        activityIndicator.startAnimating()
    }
    
    func hideLoading() {
        self.setTitle(originalButtonText, for: .normal)
        activityIndicator.stopAnimating()
    }
}
