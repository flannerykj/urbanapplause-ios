//
//  CGRect.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-28.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public extension CGRect {
    var area: CGFloat {
        return self.height * self.width
    }
}
