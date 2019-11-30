//
//  IconButton.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class IconButton: UIButton {
    private let minimumHitArea = CGSize(width: 44, height: 44)
    
    // Style
    var defaultImage: UIImage? {
        didSet {
            self.updateStyleForState()
        }
    }
    var activeImage: UIImage? {
        didSet {
            self.updateStyleForState()
        }
    }
    var selectedImage: UIImage?

    var defaultIconColor: UIColor? {
        didSet {
            iconView.tintColor = defaultIconColor
        }
    }
    var activeIconColor: UIColor?

    var defaultBackgroundColor: UIColor? {
        didSet {
            self.backgroundColor = defaultBackgroundColor
        }
    }
    var activeBackgroundColor: UIColor?

    var defaultShadowRadius: CGFloat = 0 {
        didSet {
            self.layer.shadowRadius = defaultShadowRadius
        }
    }
    var activeShadowRadius: CGFloat = 0

    var defaultShadowOpacity: Float = 0 {
        didSet {
            self.layer.shadowOpacity = defaultShadowOpacity
        }
    }
    var activeShadowOpacity: Float = 0

    // Views
    var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // States
    override var isHighlighted: Bool {
        didSet {
            updateStyleForState()
        }
    }
    override var isSelected: Bool {
        didSet {
            updateStyleForState()
        }
    }
    override var isEnabled: Bool {
        didSet {
            updateStyleForState()
        }
    }
    lazy var heightConstraint = heightAnchor.constraint(equalToConstant: 0)
    lazy var widthConstraint = widthAnchor.constraint(equalToConstant: 0)
    required init(image: UIImage?,
                  activeImage: UIImage? = nil,
                  imageColor: UIColor? = UIColor.lightGray,
                  activeImageColor: UIColor? = UIColor.darkGray,
                  backgroundColor: UIColor? = nil,
                  activeBackgroundColor: UIColor? = nil,
                  size: CGSize = CGSize(width: 24, height: 24),
                  imageSize: CGSize? = nil,
                  target: Any? = nil,
                  action: Selector? = nil) {

        self.defaultIconColor = imageColor
        self.defaultBackgroundColor = backgroundColor

        self.activeIconColor = activeImageColor ?? imageColor
        self.activeBackgroundColor = activeBackgroundColor ?? backgroundColor

        self.defaultImage = image
        self.selectedImage = image
        self.activeImage = activeImage ?? image
        
        super.init(frame: .zero)
   
        addSubview(iconView)

        heightConstraint.constant = size.height
        widthConstraint.constant = size.width
        
        NSLayoutConstraint.activate([
            heightConstraint,
            widthConstraint,

            iconView.heightAnchor.constraint(equalToConstant: (imageSize ?? size).height),
            iconView.widthAnchor.constraint(equalToConstant: (imageSize ?? size).width),
            iconView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        self.translatesAutoresizingMaskIntoConstraints = false
        
        if let selector = action {
            self.addTarget(target, action: selector, for: .touchUpInside)
        }

        self.layer.cornerRadius = size.height/2
        updateStyleForState()
    }

    func updateStyleForState() {
        switch self.state {
        case .highlighted:
            self.iconView.tintColor = self.activeIconColor
            self.layer.shadowOpacity = self.activeShadowOpacity
            self.layer.shadowRadius = self.activeShadowRadius
            self.backgroundColor = self.activeBackgroundColor
            iconView.image = activeImage?.withRenderingMode(.alwaysTemplate)
        case .selected:
            iconView.image = selectedImage?.withRenderingMode(.alwaysTemplate)
        default:
            self.iconView.tintColor = self.defaultIconColor
            self.layer.shadowOpacity = self.defaultShadowOpacity
            self.layer.shadowRadius = self.defaultShadowRadius
            self.backgroundColor = self.defaultBackgroundColor
            iconView.image = defaultImage?.withRenderingMode(.alwaysTemplate)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // if the button is hidden/disabled/transparent it can't be hit
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }

        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = self.bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
