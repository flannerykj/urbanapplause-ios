//
//  ActivityIndicator.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class ActivityIndicator: UIActivityIndicatorView {
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 24).isActive = true
        heightAnchor.constraint(equalTo: widthAnchor).isActive = true
        hidesWhenStopped = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
