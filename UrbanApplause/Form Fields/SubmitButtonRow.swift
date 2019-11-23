//
//  SubmitButtonRow.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-17.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Eureka
import UIKit

public final class CustomButtonRow: Row<CustomButtonCell>, RowType {
    
    required public init(tag: String?) {
        super.init(tag: tag)
        displayValueFor = nil
        // cellProvider = CellProvider<SubmitButtonCell>(nibName: "WeekDaysCell")
    }
}

public class CustomButtonCell: Cell<String>, CellType {
    
    required public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var button = UIButton()
    
    public override func setup() {
        super.setup()
        height = { 65 }
        selectionStyle = .none
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        button.setTitle("Submit", for: .normal)
        button.style()
        contentView.addSubview(button)
        contentView.addConstraints(layoutConstraints())
    }
    
    private func layoutConstraints() -> [NSLayoutConstraint] {
        let views = [
            "button": button,
            "contentView": contentView
        ]
        let metrics = ["vMargin": 8.0]
        return NSLayoutConstraint.constraints(withVisualFormat: "H:|-[button]-|",
                                              options: .alignAllLastBaseline,
                                              metrics: metrics, views: views)
            + NSLayoutConstraint.constraints(withVisualFormat: "V:|-(vMargin)-[button]-(vMargin)-|",
                                             options: .alignAllLastBaseline, metrics: metrics, views: views)
    }
}
