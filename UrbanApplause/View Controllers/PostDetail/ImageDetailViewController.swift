//
//  ImageDetailViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//
import Foundation
import UIKit
import Shared

class ImageDetailViewController: UIViewController, UIScrollViewDelegate {
    var file: File
    var appContext: AppContext
    var imageDownloadJob: FileDownloadJob?
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                self.imageDownloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    init(file: File, placeholderImage: UIImage?, appContext: AppContext) {
        
        self.file = file
        self.appContext = appContext
        self.imageDownloadJob = appContext.fileCache.getJobForFile(file, isThumb: false)
        
        super.init(nibName: nil, bundle: nil)
        self.imageView.state = .complete(placeholderImage)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    var imageView = LoadableImageView(initialState: .empty,
                                      maskToBounds: false,
                                      contentMode: .scaleAspectFit)
        
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
        }
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        view.backgroundColor = UIColor.systemGray6
       
        if let job = self.imageDownloadJob {
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        self.imageView.state = .complete(image)
                        self.updateZoomScale(for: image)
                    } else {
                        log.error("invalid image data")
                    }
                }
            }, onUpdateProgress: { progress in
                DispatchQueue.main.async {
                    self.imageView.state = .downloading(progress)
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
