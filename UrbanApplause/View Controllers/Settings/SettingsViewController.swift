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

class SettingsViewController: UIViewController {

    var store: Store
    var mainCoordinator: MainCoordinator
    
    init(store: Store, mainCoordinator: MainCoordinator) {
        self.store = store
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var tableHeaderView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0))
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Settings"
        view.addSubview(tableView)
        tableView.fill(view: self.view)
    }
}

// MARK: - Table view data source
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    var sections: [[SettingsItem]] {
        return [
            [.termsOfService, .privacyPolicy],
            [.logout]
        ]
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HelpItem", for: indexPath)
        let settingsItem = sections[indexPath.section][indexPath.row]
        cell.textLabel?.text = settingsItem.title
        cell.textLabel?.font = TypographyStyle.body.font
        cell.detailTextLabel?.font = TypographyStyle.body.font
        cell.imageView?.image = settingsItem.image
        
        if settingsItem == .logout {
            // cell.textLabel?.style(as: .link)
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 32))
        view.backgroundColor = UIColor.systemGray6
        return view
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let helpItem = sections[indexPath.section][indexPath.row]
        switch helpItem {
        case .logout:
            mainCoordinator.endSession(authContext: .userInitiated)
        default:
            if let url = helpItem.url {
                let vc = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            } else if let vc = helpItem.viewController {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
extension SettingsViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}
}
