//
//  PostImageCell.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-14.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class PostImageCell: UICollectionViewCell {
    static let reuseIdentifier = "PostCell"
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                self.downloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    var downloadJob: FileDownloadJob? {
        didSet {
            guard let job = downloadJob else { log.debug("job is nil"); return }
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    self.photoView.image = UIImage(data: data)
                }
            })
        }
    }
    
    var post: Post?
    var photoView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 100)
            ])
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.image = UIImage(named: "placeholder")
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(photoView)
        photoView.fill(view: self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.subscriber = nil
    }
}
