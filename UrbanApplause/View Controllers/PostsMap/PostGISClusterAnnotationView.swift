//
//  PostGISClusterAnnotationView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-12.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PostGISClusterAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = "PostGISCluster"
    
    override var annotation: MKAnnotation? {
        didSet {
            if let postCluster = annotation as? PostCluster {
                if postCluster.count > 1 {
                    clusterMembersCountLabel.text = String(postCluster.count)
                    clusterMembersCountView.isHidden = false
                } else {
                    clusterMembersCountView.isHidden = true
                }
            } else if let postCluster = annotation as? MKClusterAnnotation {
                if let members = postCluster.memberAnnotations as? [PostCluster] {
                    let sum = members.map { $0.count }.reduce(0, +)
                    if sum > 1 {
                        clusterMembersCountLabel.text = String(sum)
                        clusterMembersCountView.isHidden = false
                    } else {
                        clusterMembersCountView.isHidden = true
                    }
                }
            }
        }
    }
    
    var contentView = AnnotationContentView()
    var clusterMembersCountLabel = UILabel()
    
    lazy var clusterMembersCountView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clusterMembersCountLabel)
        clusterMembersCountLabel.fillWithinMargins(view: view)
        view.backgroundColor = UIColor.systemBlue
        view.layer.cornerRadius = 8
        clusterMembersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        clusterMembersCountLabel.textColor = .white
        return view
    }()

    var downloadJob: FileDownloadJob? {
        didSet {
            guard let job = downloadJob else {
                return
            }
            _ = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    self.contentView.setImage(UIImage(data: data))
                }
            })
        }
    }

    /// Animation duration in seconds.

    let animationDuration: TimeInterval = 0.25

    // MARK: - Initialization methods

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        canShowCallout = false
        markerTintColor = .clear
        clusteringIdentifier = nil // MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        glyphText = ""
        addSubview(contentView)
        addSubview(clusterMembersCountView)
        clusterMembersCountView.centerYAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        clusterMembersCountView.centerXAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc func didTap(_: Any) {
        super.setSelected(true, animated: true)
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView != nil {
            self.superview?.bringSubviewToFront(self)
        }
        return hitView
    }
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let rect = self.bounds
        var isInside: Bool = rect.contains(point)
        if !isInside {
            for view in self.subviews {
                isInside = view.frame.contains(point)
                if isInside {
                    break
                }
            }
        }
        return isInside
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.contentView.setImage(nil)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        centerOffset = CGPoint(x: -contentView.bounds.width/2, y: -contentView.bounds.height)
    }
}

class AnnotationContentView: UIView {
    static let width: CGFloat = 75
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
    private lazy var imageView = UIImageView(frame: self.frame.inset(by: imageInsets))
    
    var shadowLayer: CAShapeLayer?
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: AnnotationContentView.width, height: AnnotationContentView.width))
        self.imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
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
