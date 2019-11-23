//
//  NonClippingLabel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class NonClippingLabel: UILabel {
    let GUTTER: CGFloat = 2
    
    override func draw(_ rect: CGRect) {
        var newRect = rect
        newRect.origin.x = rect.origin.x + GUTTER
        newRect.size.width = rect.size.width - 2 * GUTTER
        self.attributedText?.draw(in: newRect)
    }
    
    override var alignmentRectInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: GUTTER)
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += GUTTER
        return size
    }
}
