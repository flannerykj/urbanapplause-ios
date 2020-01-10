//
//  ErrorView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared
import SnapKit

class ErrorView: UIView {

    var errorMessage: String? {
        didSet {
            errorLabel.text = errorMessage
            errorLabel.sizeToFit()
            isHidden = errorMessage == nil || errorMessage?.count == 0
            setNeedsLayout()
        }
    }

    var backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.error
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.1
        return view
    }()

    var errorLabel = UILabel(type: .error, text: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layoutMargins = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        addSubview(backgroundView)
        backgroundView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }
        layer.borderColor = UIColor.error.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 24
        clipsToBounds = true
        addSubview(errorLabel)
        errorLabel.fillWithinMargins(view: self)
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
