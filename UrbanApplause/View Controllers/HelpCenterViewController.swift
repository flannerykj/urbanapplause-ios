//
//  HelpCenterViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import SafariServices

enum HelpItem: Int, CaseIterable {
    case termsOfService, privacyPolicy
    
    var title: String {
        switch self {
        case .termsOfService:
            return "Terms of Service"
        case .privacyPolicy:
            return "Privacy Policy"
        }
    }

    var url: URL? {
        switch self {
        case .termsOfService:
            return Config.tosURL
        case .privacyPolicy:
            return Config.privacyURL
        }
    }
    var viewController: UIViewController? {
        switch self {
        default: return nil
        }
    }
}

class HelpCenterViewController: UIViewController {

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
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HelpItem")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        tableView.backgroundColor = UIColor.backgroundMain
        tableView.separatorColor = .systemGray
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Help Center"
        view.addSubview(tableView)
        tableView.fill(view: self.view)
    }
}

extension HelpCenterViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HelpItem.allCases.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HelpItem", for: indexPath)
        cell.textLabel?.text = HelpItem(rawValue: indexPath.row)?.title
        cell.contentView.backgroundColor = UIColor.backgroundMain
        cell.accessoryType = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let helpItem = HelpItem(rawValue: indexPath.row)
        if let url = helpItem?.url {
            let vc = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        } else if let vc = helpItem?.viewController {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
extension HelpCenterViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    }
}
