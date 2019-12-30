//
//  LoadableImageView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol LoadableImageViewProtocol {
    var state: LoadableImageState { get set }
    var progressView: UIView { get }
    func setProgress(_ progress: Float)
    func setImage(_ image: UIImage?)
}
extension LoadableImageViewProtocol {
    func updateViewForState() {
        switch self.state {
        case .empty:
            self.setImage(nil)
            self.progressView.isHidden = true
        case .downloading(let progress):
            self.progressView.isHidden = false
            setProgress(progress ?? 0)
        case .complete(let image):
            self.setImage(image)
            self.progressView.isHidden = true
        case .error:
            self.setImage(UIImage(systemName: "exclamationamrk.triangle"))
            self.progressView.isHidden = true
        }
    }
}

enum LoadableImageState {
    case empty, downloading(_ progress: Float?), complete(UIImage?), error(Error)
}

class LoadableImageView: UIImageView, LoadableImageViewProtocol {
    var state: LoadableImageState = .empty {
        didSet {
            self.updateViewForState()
        }
    }
    
    /* lazy var errorImageView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "exclamationamrk.triangle"))
        view.isHidden = true
        return view
    }() */
    
    lazy var progressBar = UIProgressView()
    
    init(initialState: LoadableImageState = .empty,
         maskToBounds: Bool = true,
         contentMode: UIImageView.ContentMode = .scaleAspectFill) {
        
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = maskToBounds
        self.contentMode = contentMode
        layer.masksToBounds = maskToBounds
        // image = UIImage(named: "placeholder")
        addSubview(progressBar)
        // addSubview(errorImageView)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor = .systemPink
        progressBar.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.2)
        NSLayoutConstraint.activate([
            progressBar.leftAnchor.constraint(equalTo: self.leftAnchor),
            progressBar.rightAnchor.constraint(equalTo: self.rightAnchor),
            progressBar.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 10),
            // errorImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            // errorImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        state = initialState
        updateViewForState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProgress(_ progress: Float) {
        self.progressBar.progress = progress
    }
    func setImage(_ image: UIImage?) {
        self.image = image
    }
    var progressView: UIView {
        return self.progressBar
    }
}
