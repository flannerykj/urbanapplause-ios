//
//  AnnotationContentView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class AnnotationContentView: UIView {
    static let width: CGFloat = 75
    static let height: CGFloat = 75
    
    var errorMessage: String? {
        didSet {
            if errorMessage == nil {
                errorImageView.isHidden = true
                activityIndicator.startAnimating()
            } else {
                errorImageView.isHidden = false
                activityIndicator.stopAnimating()
            }
        }
    }
    var cornerRadius: CGFloat = 8
    var imagePadding: CGFloat = 3
    var arrowHeight: CGFloat = 10
    var arrowWidth: CGFloat = 16

    lazy var imageInsets = UIEdgeInsets(top: imagePadding,
                                        left: imagePadding,
                                        bottom: imagePadding + arrowHeight,
                                        right: imagePadding)
    
    public func setImage(_ image: UIImage?) {
        imageView.image = image
    }
    public func getImage() -> UIImage? {
        return imageView.image
    }
    private var errorImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        imageView.isHidden = true // hidden until error message is set
        imageView.tintColor = UIColor.systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var imageView = UIImageView(frame: self.frame.inset(by: imageInsets))
    var shadowLayer: CAShapeLayer?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: AnnotationContentView.width, height: AnnotationContentView.height))
        self.imageView.contentMode = .scaleAspectFill
        self.addSubview(activityIndicator)
        self.addSubview(errorImageView)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()
        self.addSubview(imageView)

        NSLayoutConstraint.activate([
            activityIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            errorImageView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            errorImageView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor)
        ])

        self.layer.cornerRadius = 8
        self.clipsToBounds = true
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.3
        self.layer.shadowOffset = CGSize(width: 0, height: 6)
        self.layer.shadowRadius = 6
        self.imageView.layer.cornerRadius = 5
        self.imageView.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let path = UIBezierPath()
        
        // origin
        let origin = CGPoint(x: rect.origin.x + cornerRadius, y: rect.origin.y)
        path.move(to: origin)
        
        // top edge
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        
        // top right corner
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
                          controlPoint: CGPoint(x: rect.maxX, y: rect.minY))
        
        // right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius - arrowHeight))
        
        // bottom right corner
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - arrowHeight),
                          controlPoint: CGPoint(x: rect.maxX, y: rect.maxY - arrowHeight))
        
        // bottom edge - right side
        path.addLine(to: CGPoint(x: rect.midX + arrowWidth/2, y: rect.maxY - arrowHeight))
        
        // arrow vertex
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - arrowWidth/2, y: rect.maxY - arrowHeight))

        // bottom edge - left side
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - arrowHeight))
        
        // bottom right corner
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - arrowHeight - cornerRadius),
                          controlPoint: CGPoint(x: rect.minX, y: rect.maxY - arrowHeight))
        
        // left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        
        // top left corner
        path.addQuadCurve(to: origin, controlPoint: CGPoint(x: rect.minX, y: rect.minY))
        path.close()
        UIColor.white.setFill()
        path.fill()
        
        self.layer.shadowPath = path.cgPath
    }
}
