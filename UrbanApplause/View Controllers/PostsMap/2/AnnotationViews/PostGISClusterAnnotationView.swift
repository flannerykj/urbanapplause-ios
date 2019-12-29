//
//  PostGISClusterAnnotationView2.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-29.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PostGISClusterAnnotationView: MKMarkerAnnotationView, PostAnnotationViewProtocol {
    static let reuseIdentifier = "PostGISClusterAnnotationView"
    
    var fileCache: FileService?
    var contentView = AnnotationContentView()

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
        markerTintColor = .clear
        clusteringIdentifier = "postGISCluster"
        addSubview(contentView)
        addSubview(clusterMembersCountView)
        clusterMembersCountView.centerYAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        clusterMembersCountView.centerXAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        // contentView.backgroundColor = .green

    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        // displayPriority = .defaultHigh
        contentView.setImage(nil)
        glyphText = ""
        
        if let postCluster = annotation as? PostCluster {
            if let coverPhotoThumb = postCluster.cover_image_thumb {
                downloadJob = fileCache?.getJobForFile(coverPhotoThumb)
            } else {
                downloadJob = fileCache?.getJobForFile(postCluster.cover_image)
            }
            clusterMembersCountLabel.text = String(postCluster.count)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

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
        downloadJob = nil
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        centerOffset = CGPoint(x: -contentView.bounds.width/2, y: -contentView.bounds.height)
    }
}
