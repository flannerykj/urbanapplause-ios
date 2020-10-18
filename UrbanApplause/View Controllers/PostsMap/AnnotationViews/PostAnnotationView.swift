//
//  PostClusterView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Shared

protocol PostAnnotationViewProtocol {
    var contentView: AnnotationContentView { get set }
}

class PostAnnotationView: MKMarkerAnnotationView, PostAnnotationViewProtocol {
    static let reuseIdentifier = "PostAnnotationView"
    
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

    // Animation duration in seconds.

    let animationDuration: TimeInterval = 0.25

    // MARK: - Initialization methods

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        markerTintColor = .clear
        clusteringIdentifier = "post"
        addSubview(contentView)
        contentView.backgroundColor = .blue // For debugging
    }
    override func prepareForDisplay() {
        super.prepareForDisplay()
        contentView.setImage(nil)
        // displayPriority = .defaultHigh
        glyphText = ""
        
        if let post = annotation as? Post {
            if let coverPhotoThumb = post.PostImages?.first?.thumbnail {
                downloadJob = fileCache?.getJobForFile(coverPhotoThumb, isThumb: true)
            } else if let coverPhotoFull = post.PostImages?.first {
               downloadJob = fileCache?.getJobForFile(coverPhotoFull, isThumb: true)
            }
        }
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
        downloadJob = nil
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        centerOffset = CGPoint(x: -contentView.bounds.width/2, y: -contentView.bounds.height)
    }
}
