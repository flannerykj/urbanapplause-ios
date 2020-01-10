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
import Shared

class PostMKClusterAnnotationView: MKAnnotationView, PostAnnotationViewProtocol {
    static let reuseIdentifier = "PostMKClusterAnnotationView"
    var fileCache: FileService?
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        contentView.setImage(nil)
        if let cluster = annotation as? MKClusterAnnotation {
            if let posts = cluster.memberAnnotations as? [Post] {
                let sorted = posts.sorted(by: {
                    guard let firstDate = $0.createdAt else { return false }
                    guard let secondDate = $1.createdAt else { return true }
                    return firstDate > secondDate
                })
                if let coverPhotoThumb = sorted.first?.PostImages?.first?.thumbnail {
                    downloadJob = fileCache?.getJobForFile(coverPhotoThumb)
                } else if let coverPhotoFull = sorted.first?.PostImages?.first {
                    downloadJob = fileCache?.getJobForFile(coverPhotoFull)
                }
            } else if let posts = cluster.memberAnnotations as? [PostCluster] {
                let sorted = posts.sorted(by: {
                    return $0.cover_post_id > $1.cover_post_id
                })
                if let coverPhotoThumb = sorted.first?.cover_image_thumb {
                    downloadJob = fileCache?.getJobForFile(coverPhotoThumb)
                } else if let coverPhotoFull = sorted.first?.cover_image {
                    downloadJob = fileCache?.getJobForFile(coverPhotoFull)
                }
            }
            let count = cluster.memberAnnotations.count
            if count == 1 {
                clusterMembersCountView.isHidden = true
            } else {
                clusterMembersCountLabel.text = String(count)
                clusterMembersCountView.isHidden = false
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
        collisionMode = .rectangle
        addSubview(contentView)
        addSubview(clusterMembersCountView)
        clusterMembersCountView.centerYAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        clusterMembersCountView.centerXAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        // contentView.backgroundColor = .orange
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

    override func layoutSubviews() {
        super.layoutSubviews()
        centerOffset = CGPoint(x: -contentView.bounds.width/2, y: -contentView.bounds.height)
    }
}
