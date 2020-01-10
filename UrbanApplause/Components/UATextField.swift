//
//  UATextField.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class UATextField: UITextField {
    let activeColor: UIColor = .systemTeal
    let inactiveColor: UIColor = .systemGray
    
    override var leftView: UIView? {
        didSet {
            updateStyleForState()
        }
    }
    override var rightView: UIView? {
        didSet {
            updateStyleForState()
        }
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        self.addTarget(self, action: #selector(editingStateChanged(_:)), for: .allEditingEvents)
        self.font = TypographyStyle.body.font
    }
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.frame.size.width = self.superview?.frame.width ?? 0
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return contentRect(forBounds: bounds)
    }
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return contentRect(forBounds: bounds)
    }
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return contentRect(forBounds: bounds)
    }
    
    private func contentRect(forBounds bounds: CGRect) -> CGRect {
        var leftPadding: CGFloat = 0
        var rightPadding: CGFloat  = 15
        let topPadding: CGFloat = 15
        let bottomPadding: CGFloat = 15
        
        if leftViewMode == .always, let leftViewWidth = leftView?.bounds.width {
            leftPadding += leftViewWidth + 8
        }
        if rightViewMode == .always, let rightViewWidth = rightView?.bounds.width {
            rightPadding += rightViewWidth + 8
        }
        return bounds.inset(by: UIEdgeInsets(top: topPadding,
                                             left: leftPadding,
                                             bottom: bottomPadding,
                                             right: rightPadding))
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        (isEditing ? activeColor : inactiveColor).setStroke()
        path.lineWidth = 2
        path.stroke()
    }
    
    @objc func editingStateChanged(_: Any) {
        updateStyleForState()
    }
    func updateStyleForState() {
        if isEditing {
            (self.leftView as? UIImageView)?.tintColor = activeColor
        } else {
            (self.leftView as? UIImageView)?.tintColor = inactiveColor
        }
        setNeedsDisplay() // redraw bottom line
    }
}
