//
//  LoadableImageView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit


class LoadableImageView: UIImageView {
    enum State {
        case empty, loading, complete(UIImage?), error(Error)
    }
    
    var state: State = .empty {
        didSet {
            self.updateViewForState()
        }
    }
    
    lazy var errorImageView: UIImageView = {
        let view = UIImageView(image: UIImage(systemName: "exclamationamrk.triangle"))
        view.isHidden = true
        return view
    }()
    
    let imageLoadingIndicator = CircularLoader()

    init(initialState: State = .empty) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        contentMode = .scaleAspectFill
        layer.masksToBounds = true
        image = UIImage(named: "placeholder")
        addSubview(imageLoadingIndicator)
        addSubview(errorImageView)
        NSLayoutConstraint.activate([
            imageLoadingIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            errorImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            errorImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
        state = initialState
        updateViewForState()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateViewForState() {
        switch self.state {
        case .empty:
            self.image = nil
            self.errorImageView.isHidden = true
            self.imageLoadingIndicator.hide()
        case .loading:
            self.image = nil
            self.errorImageView.isHidden = true
            self.imageLoadingIndicator.showAndAnimate()
        case .complete(let image):
            self.image = image
            self.errorImageView.isHidden = true
            self.imageLoadingIndicator.hide()
        case .error(_):
            self.image = nil
            self.errorImageView.isHidden = false
            self.imageLoadingIndicator.hide()
        }
    }
}
