//
//  FlagPostResultViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-31.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class ReportAnIssueResultViewController: UIViewController {
    
    let titleLabel = UILabel(type: .h3,
                             text: Strings.ReportIssueSuccessMessageTitle)
    let subtitleLabel = UILabel(type: .body,
                                text: Strings.ReportIssueSuccessMessageBody)

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        let leftButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = leftButton // replace back button with emtpy item, so user can't resubmit form
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(pressedDone(_:)))
        navigationItem.rightBarButtonItem = doneButton
        view.layoutMargins.top = 24
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            stackView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor)
        ])
    }
    
    @objc func pressedDone(_: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
