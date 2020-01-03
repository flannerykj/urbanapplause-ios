//
//  TabbedToolbar.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol ToolbarTabItemDelegate: class {}

struct ToolbarTabItem {
    weak var delegate: ToolbarTabItemDelegate?
    var icon: UIImage?
    var title: String
    var tint: UIColor?
    var viewController: TabContentViewController
    
    init(title: String, viewController: TabContentViewController, delegate: ToolbarTabItemDelegate) {
        self.title = title
        self.viewController = viewController
        self.delegate = delegate
    }
}

class TabbedToolbar: UIView {
    var tabItems: [ToolbarTabItem]
    
    init(tabItems: [ToolbarTabItem]) {
        self.tabItems = tabItems
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ToolbarTabButton: UIButton {

    let height: CGFloat = 62
    var activeTint: UIColor?
    var defaultTint = UIColor.lightGray

    override var isHighlighted: Bool {
        didSet {
            updateStyle()
        }
    }
    override var isSelected: Bool {
        didSet {
            updateStyle()
        }
    }

    let label = UILabel(type: .strong)

    required init(title: String, icon: UIImage?, activeTint: UIColor?, target: Any, action: Selector) {
        super.init(frame: .zero)
        self.activeTint = activeTint

        translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)

        label.text = title
        label.sizeToFit()
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.rightAnchor.constraint(equalTo: self.rightAnchor),
            label.leftAnchor.constraint(equalTo: self.leftAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        updateStyle()
    }
    func updateStyle() {
        let useActiveStyle = state == .highlighted || state == .selected
        label.textColor = useActiveStyle ? activeTint : defaultTint
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
