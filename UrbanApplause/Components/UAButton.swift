//
//  File.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-17.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class UAButton: UIButton {
    private let imageWidth: CGFloat = 24
    // @MARK - Public properties
    public var normalProperties: MutableButtonProperties
    public var highlightedProperties: MutableButtonProperties
    public var selectedProperties: MutableButtonProperties
    public var disabledProperties: MutableButtonProperties
    
    public func showLoading() {
        originalButtonText = self.title(for: .normal)
        self._titleLabel.text = ""
        activityIndicator.startAnimating()
    }
    public func hideLoading() {
        self._titleLabel.text = originalButtonText
        activityIndicator.stopAnimating()
    }
    public func enable() {
        isEnabled = true
        alpha = 1.0
    }
    public func disable() {
        isEnabled = false
        alpha = 0.5
    }
    public func updateStyleForState() {
        switch self.state {
        case .selected:
            selectedProperties.applyToButton(self)
        case .highlighted:
            highlightedProperties.applyToButton(self)
        case .disabled:
            disabledProperties.applyToButton(self)
        default:
            normalProperties.applyToButton(self)
        }
    }
    public func setLeftImage(_ image: UIImage?, color: UIColor? = nil) {
        self.leftImageView.tintColor = color
        self.leftImageView.image = image
        updateConstraints()
    }
    public func setRightImage(_ image: UIImage?, color: UIColor? = nil) {
        self.rightImageView.tintColor = color
        self.rightImageView.image = image
        updateConstraints()
    }
    
    init(type: ButtonStylePreset = .link, title: String, target: Any, action: Selector, rightImage: UIImage? = nil) {
        normalProperties = MutableButtonProperties.createFromPreset(type, forState: .normal)
        highlightedProperties = MutableButtonProperties.createFromPreset(type, forState: .highlighted)
        selectedProperties = MutableButtonProperties.createFromPreset(type, forState: .selected)
        disabledProperties = MutableButtonProperties.createFromPreset(type, forState: .disabled)
        
        super.init(frame: .zero)
        
        addTarget(target, action: action, for: .touchUpInside)
        _titleLabel.text = title
        translatesAutoresizingMaskIntoConstraints = false
        originalButtonText = title
        addSubview(activityIndicator)
        addSubview(leftImageView)
        addSubview(_titleLabel)
        addSubview(rightImageView)
        activityIndicator.color = type.defaultTextColor
        NSLayoutConstraint.activate([
            _titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            titleLabelCenterXAnchor,
            activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            leftImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rightImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            leftImageToLeftEdgeConstraint,
            rightImageToRightEdgeConstraint
        ])
        activityIndicator.hidesWhenStopped = true
        if let height = type.height {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        _titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        switch type {
        case .icon(_, let size):
            if let img = type.image {
                setImage(img, for: .normal)
            }
            let size = size ?? 30
            imageView?.frame = CGRect(x: 0, y: 0, width: size, height: size)
            imageView?.contentMode = .scaleAspectFit
            
            widthAnchor.constraint(equalToConstant: size).isActive = true
            setContentCompressionResistancePriority(UILayoutPriority.defaultHigh,
                                                    for: NSLayoutConstraint.Axis.horizontal)
        default:
            break
        }
        layer.cornerRadius = 8
        _titleLabel.textAlignment = .center
        setTitleColor(normalProperties.textColor, for: .normal)
        updateStyleForState()
    }
    // @MARK - Private properties
    
    private var originalButtonText: String?
    private var activityIndicator = ActivityIndicator()
    private var contentPadding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    private var imageToTextPadding: CGFloat = 8
    
    fileprivate lazy var leftImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: imageWidth).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: imageWidth).isActive = true
        return imageView
    }()
    
    private lazy var _titleLabel = UILabel(type: .body)
    
    fileprivate lazy var rightImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.heightAnchor.constraint(equalToConstant: imageWidth).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: imageWidth).isActive = true
        return imageView
    }()
    
    private lazy var leftImageToLeftEdgeConstraint = leftImageView.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor)
    private lazy var rightImageToRightEdgeConstraint = rightImageView.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor)
    
    // use when left/right images (respectively) not present
    private lazy var titleLabelToLeftEdgeConstraint = _titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: self.leftAnchor)
    private lazy var titleLabelToRightEdgeConstraint = _titleLabel.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor)
    
    // use when image(s) present
    private lazy var titleLabelToLeftImageConstraint = _titleLabel.leftAnchor.constraint(equalTo: leftImageView.rightAnchor)
    private lazy var titleLabelToRightImageConstraint = _titleLabel.rightAnchor.constraint(equalTo: rightImageView.leftAnchor)
    
    
    private lazy var titleLabelCenterXAnchor = _titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor)
    
    private var hasLeftImage: Bool {
        return leftImageView.image != nil
    }
    private var hasRightImage: Bool {
        return rightImageView.image != nil
    }
    
    override func updateConstraints() {
        titleLabelToLeftImageConstraint.constant = self.imageToTextPadding
        titleLabelToRightImageConstraint.constant = -self.imageToTextPadding
        
        leftImageToLeftEdgeConstraint.constant = self.contentPadding.left
        rightImageToRightEdgeConstraint.constant = -self.contentPadding.right
        
        titleLabelToLeftEdgeConstraint.constant = self.contentPadding.left
        titleLabelToRightEdgeConstraint.constant = -self.contentPadding.right
        
        titleLabelToLeftImageConstraint.isActive = hasLeftImage
        titleLabelToRightEdgeConstraint.isActive = hasRightImage
        
        log.debug("has left image: \(hasLeftImage)")
        log.debug("has right image: \(hasRightImage)")

        titleLabelToLeftEdgeConstraint.isActive = !hasLeftImage
        titleLabelToRightEdgeConstraint.isActive = !hasRightImage
        
        if hasLeftImage && !hasRightImage {
            titleLabelCenterXAnchor.constant = (imageWidth/2 + imageToTextPadding/2)
        } else if !hasLeftImage && hasRightImage {
            titleLabelCenterXAnchor.constant = -(imageWidth/2 + imageToTextPadding/2)
        } else {
            titleLabelCenterXAnchor.constant = 0
        }
        
        super.updateConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var titleLabel: UILabel? {
        return _titleLabel
    }
    
    override var isEnabled: Bool {
        didSet {
            updateStyleForState()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            updateStyleForState()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            updateStyleForState()
        }
    }
    override func setTitle(_ title: String?, for state: UIControl.State) {
        _titleLabel.text = title
    }
}

struct MutableButtonProperties {
    var backgroundColor: UIColor?
    var textColor: UIColor?
    var borderColor: UIColor?
    var borderWidth: CGFloat
    
    func applyToButton(_ button: UAButton) {
        button.backgroundColor = self.backgroundColor
        button.titleLabel?.textColor = self.textColor
        button.layer.borderColor = self.borderColor?.cgColor
        button.layer.borderWidth = self.borderWidth
        button.leftImageView.tintColor = self.textColor
        button.rightImageView.tintColor = self.textColor
    }
    
    static func createFromPreset(_ preset: ButtonStylePreset, forState state: UIButton.State) -> MutableButtonProperties {
        switch state {
        case .selected:
            return MutableButtonProperties(backgroundColor: preset.selectedBackgroundColor,
                                           textColor: preset.selectedTextColor,
                                           borderColor: preset.highlightedBorderColor,
                                           borderWidth: preset.defaultBorderWidth)
        case .highlighted:
            return MutableButtonProperties(backgroundColor: preset.highlightedBackgroundColor,
                                           textColor: preset.highlightedTextColor,
                                           borderColor: preset.highlightedBorderColor,
                                           borderWidth: preset.defaultBorderWidth)
        default:
            // normal
            return MutableButtonProperties(backgroundColor: preset.backgroundColor,
                                           textColor: preset.defaultTextColor,
                                           borderColor: preset.defaultBorderColor,
                                           borderWidth: preset.defaultBorderWidth)
            
        }
        
    }
}

