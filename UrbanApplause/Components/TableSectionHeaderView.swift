//
//  TableSectionHeaderView.swift
//  UrbanApplause
//
//  Created by Flann on 2020-11-28.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared


class TableSectionHeaderView: UIView {
    init(height: CGFloat, title: String) {
        super.init(frame:  CGRect(x: 0, y: 0, width: 100, height: height))
        layoutMargins = StyleConstants.defaultMarginInsets
        backgroundColor = UIColor.systemBackground
        let label = UILabel(type: .h8, text: title)
        addSubview(label)
        layoutMargins = StyleConstants.defaultPaddingInsets
        label.fillWithinMargins(view: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
