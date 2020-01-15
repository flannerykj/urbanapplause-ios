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
    
    init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    init(size: CGSize) {
        self.init(origin: .zero, size: size)
    }
}
