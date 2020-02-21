//
//  UIViewControllerExtensions.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit


public extension UIViewController {
    var isVisible: Bool {
        return self.viewIfLoaded?.window != nil
    }
}
