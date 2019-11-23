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
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100))
        return view
    }()
    lazy var tableFooterView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100))
        return view
    }()
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportReason")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
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
            let alertController = UIAlertController(title: nil, message: error.userMessage, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
            }
            var rect = self.view.frame
            rect.origin.x = self.view.frame.size.width / 20
            rect.origin.y = self.view.frame.size.height / 20
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = rect
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let reason = PostFlagReason.allCases[indexPath.row]
        onSelectReason(self, reason)
    }
}
