//
//  ImageCarouselViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class ImageCarouselViewController: UIViewController {
    var imageIndex: Int = 0
    var files: [File]
    var appContext: AppContext
    var imageDownloadJobs: [FileDownloadJob]
    var imageControllers: [UIViewController]

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: imageControllers.map { $0.view })
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        return stackView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalTo(scrollView)
        }
        scrollView.alwaysBounceVertical = false
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    init(files: [File], appContext: AppContext) {
        self.files = files
        self.appContext = appContext
        self.imageDownloadJobs = files.map { appContext.fileCache.getJobForFile($0) }
        self.imageControllers = files.map { ImageDetailViewController(file: $0,
                                                                      placeholderImage: nil,
                                                                      appContext: appContext) }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundLight
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        navigationItem.title = Strings.PhotoCarouselPaginationTitle(current: self.imageIndex + 1, total: self.files.count)
        
        let views = imageControllers.map {
            $0.view!
        }
        for view in views {
            view.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
            view.heightAnchor.constraint(equalTo: self.view.layoutMarginsGuide.heightAnchor).isActive = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = stackView.bounds.size
    }
}
extension ImageCarouselViewController: UIScrollViewDelegate {
    
}
