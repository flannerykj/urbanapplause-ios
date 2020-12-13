//
//  PostV2Cell.swift
//  UrbanApplause
//
//  Created by Flann on 2020-12-12.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared


class PostV2Cell: UICollectionViewCell {
    
    var indexPath: IndexPath?
    var appContext: AppContext?
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                // self.downloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    var activityIndicator = ActivityIndicator()
    
    var downloadJob: FileDownloadJob? {
        didSet {
            guard let job = downloadJob else {
                return
            }
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    self.photoView.image = UIImage(data: data)
                }
            })
        }
    }
    
    var post: Post? {
        didSet {
            if post != nil {
                isLoading = false
            }
        }
    }
    var photoView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/4),
            view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
            ])
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(photoView)
        photoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
