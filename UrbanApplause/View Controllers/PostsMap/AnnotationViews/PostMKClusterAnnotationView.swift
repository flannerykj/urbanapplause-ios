//
//  PostClusterAnnotation.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PostMKClusterAnnotationView: MKMarkerAnnotationView {
    static let reuseIdentifier = "PostMKClusterAnnotationView"
    
    override var annotation: MKAnnotation? {
        didSet {
            if let cluster = annotation as? MKClusterAnnotation {
                clusterMembersCountLabel.text = String(cluster.memberAnnotations.count)
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
        contentView.backgroundColor = .yellow
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
