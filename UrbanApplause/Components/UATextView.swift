//
//  UATextView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-29.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class UATextView: UITextView {
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        self.isUserInteractionEnabled = true
        self.textContainer.lineFragmentPadding = 0
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isEditable = false
        self.isScrollEnabled = false
        self.isUserInteractionEnabled = true
        self.isSelectable = true
        self.backgroundColor = UIColor.clear
        self.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.linkTextAttributes = [
            .font: TypographyStyle.link.font,
            .foregroundColor: UIColor.systemBlue
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var alignmentRectInsets: UIEdgeInsets {
        return UIEdgeInsets.allZero
    }
}
