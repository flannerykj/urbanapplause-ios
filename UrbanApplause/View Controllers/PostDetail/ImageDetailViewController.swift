//
//  ImageDetailViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//
import Foundation
import UIKit

class ImageDetailViewController: UIViewController, UIScrollViewDelegate {
    var file: File
    var mainCoordinator: MainCoordinator
    var imageDownloadJob: FileDownloadJob?
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                self.imageDownloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    init(file: File, mainCoordinator: MainCoordinator) {
        self.file = file
        self.mainCoordinator = mainCoordinator
        self.imageDownloadJob = mainCoordinator.fileCache.download(file: file)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let activityIndicator = ActivityIndicator()
        
    var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
        
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        imageView.fill(view: scrollView)
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        view.addSubview(scrollView)
        scrollView.fill(view: view)
        view.backgroundColor = UIColor.backgroundLight
       
        if let job = self.imageDownloadJob {
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        self.updateZoomScale(for: image)
                        self.imageView.image = image
                    } else {
                        log.error("invalid image data")
                    }
                }
            })
        }
    }
    
    func updateZoomScale(for image: UIImage) {
        scrollView.contentSize = image.size
        let scrollViewFrame = scrollView.frame
        let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
        let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
        let minScale = min(scaleWidth, scaleHeight)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 1.0
        scrollView.zoomScale = minScale
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
