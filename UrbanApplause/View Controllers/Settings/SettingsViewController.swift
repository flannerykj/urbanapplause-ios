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
import Shared
import SnapKit
//import SideMenuSwift

class SettingsViewController: UIViewController {
    private var tableViewLeftConstraint: Constraint?
    
    var store: Store
    var appContext: AppContext
    
    init(store: Store, appContext: AppContext) {
        self.store = store
        self.appContext = appContext
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
        tableView.backgroundColor = UIColor.secondarySystemBackground
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
        navigationItem.title = Strings.SettingsTabItemTitle
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
//            make.width.equalTo(SideMenuController.preferences.basic.menuWidth)
//            make.top.bottom.trailing.equalToSuperview()
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - Table view data source
extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    var sections: [[SettingsItem]] {
        if appContext.authService.isAuthenticated {
            return [
                [.termsOfService, .privacyPolicy],
                [.logout]
            ]
        }
        return [
            [.createAccount, .login],
            [.termsOfService, .privacyPolicy],
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
        if let textColor = settingsItem.textColor {
            cell.textLabel?.textColor = textColor
        }
        cell.backgroundColor = .systemBackground
        cell.textLabel?.text = settingsItem.title
        cell.textLabel?.font = TypographyStyle.body.font
        cell.detailTextLabel?.font = TypographyStyle.body.font
        cell.imageView?.image = settingsItem.image
        cell.accessoryType = settingsItem.accessoryType
        return cell
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 32))
        return view
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let helpItem = sections[indexPath.section][indexPath.row]
        switch helpItem {
        case .logout:
            confirmLogout()
        case .profile:
            guard let user = appContext.store.user.data else { return }
            let profileVC = ProfileViewController(user: user, appContext: appContext)
            pushControllerToContentView(profileVC)
        case .createAccount, .login:
            self.showAuth(isNewUser: helpItem == .createAccount, appContext: self.appContext)
        case .privacyPolicy, .termsOfService:
            if let url = helpItem.url {
                let vc = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            } else if let vc = helpItem.viewController {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    private func confirmLogout() {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            alert.dismiss(animated: true, completion: {
                self?.clearTableSelection()
            })
        })
        let logoutAction = UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] _ in
            alert.dismiss(animated: true, completion: {
                self?.clearTableSelection()
            })
            self?.appContext.endSession()
        })
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = view.bounds
            alert.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }
        present(alert, animated: true, completion: nil)
    }
    
    private func clearTableSelection() {
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }
    
    private func pushControllerToContentView(_ controller: UIViewController) {
//        sideMenuController?.hideMenu()
//        if let navController = sideMenuController?.contentViewController as? UINavigationController {
//            navController.pushViewController(controller, animated: true)
//        } else {
//            navigationController?.pushViewController(controller, animated: true)
//        }
        navigationController?.pushViewController(controller, animated: true)
    }
}
extension SettingsViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {}
}
