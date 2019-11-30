//
//  FlagPostViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-31.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Eureka

class ReportAnIssueViewController: UIViewController {
    
    var store: Store
    var onSelectReason: (ReportAnIssueViewController, PostFlagReason) -> Void
    var didSubmit: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.navigationController?.pushViewController(ReportAnIssueResultViewController(), animated: true)
            }
        }
    }
    var isSubmitting: Bool = false {
        didSet {
            if isSubmitting {
                loader.startAnimating()
            } else {
                loader.stopAnimating()
            }
        }
    }

    init(store: Store, onSelectReason: @escaping (ReportAnIssueViewController, PostFlagReason) -> Void) {
        self.store = store
        self.onSelectReason = onSelectReason
        super.init(nibName: nil, bundle: nil)
    }
    
    var loader = ActivityIndicator()
    lazy var loaderButton = UIBarButtonItem(customView: loader)
    
    lazy var tableHeaderView: UIView = {
        let horizontalPadding = StyleConstants.contentPadding * 2
        let verticalPadding = StyleConstants.contentPadding * 2
        let label = UILabel(type: .h3, text: "What is your objection to this content?")
        let size = label.sizeThatFits(CGSize(width: UIScreen.main.bounds.width - horizontalPadding,
                                             height: 1000))
        let view = UIView(frame: CGRect(x: 0,
                                        y: 0,
                                        width: UIScreen.main.bounds.width,
                                        height: size.height + verticalPadding))
        view.layoutMargins = StyleConstants.defaultPaddingInsets
        view.addSubview(label)
        label.fillWithinMargins(view: view)
        log.debug("size: \(size)")
        return view
    }()
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportReason")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.backgroundMain
        tableView.separatorColor = .systemGray
        return tableView
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = loaderButton
        navigationItem.title = "Report an issue"
        
        view.addSubview(tableView)
        tableView.fill(view: self.view)
    }
    
    func handleError(error: UAError) {
        DispatchQueue.main.async {
            self.isSubmitting = false
            self.showAlert(message: error.userMessage, onDismiss: nil)
        }
    }
}

extension ReportAnIssueViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PostFlagReason.allCases.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportReason", for: indexPath)
        cell.textLabel?.text = PostFlagReason.allCases[indexPath.row].title
        cell.contentView.backgroundColor = UIColor.backgroundMain
        cell.accessoryType = .none
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reason = PostFlagReason.allCases[indexPath.row]
        onSelectReason(self, reason)
    }
}
