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
import Cloudinary

class ImageDetailViewController: UIViewController, UIScrollViewDelegate {
    private let cloudinary = CLDCloudinary(configuration: CLDConfiguration(cloudName: Config.cloudinaryCloudName, apiKey: Config.cloudinaryApiKey))
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
        super.init(nibName: nil, bundle: nil)

        self.imageView.cldSetImage(publicId: file.storage_location, cloudinary: cloudinary, placeholder: placeholderImage)
        self.updateZoomScale(for: image)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    lazy var imageView: CLDUIImageView = {
        let view = CLDUIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.masksToBounds = true
        return view
    }()
        
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
        view.backgroundColor = UIColor.backgroundLight
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
