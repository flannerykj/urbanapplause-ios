//
//  ArtistGroupDetailViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class ArtistGroupDetailViewController: UITableViewController {
    private var viewModel: ArtistGroupDetailViewModel
    private var appContext: AppContext
    
    init(groupID: Int, group: ArtistGroup, appContext: AppContext) {
        self.appContext = appContext
        self.viewModel = ArtistGroupDetailViewModel(groupID: groupID, group: group, appContext: appContext)
        super.init(nibName: nil, bundle: nil)
        
        viewModel.onSetLoading = { loading in
            DispatchQueue.main.async {
                if loading {
                    self._refreshControl.beginRefreshing()
                } else {
                    self._refreshControl.endRefreshing()
                }
            }
        }
        viewModel.onSetData = { group in
            self.groupNameLabel.text = group?.name
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        viewModel.onSetError = { errorMessage in
            DispatchQueue.main.async {
                self.showAlert(title: Strings.ErrorAlertTitle, message: errorMessage, onDismiss: nil)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var _refreshControl = UIRefreshControl()
    
    lazy var groupNameLabel = UILabel(type: .h2)
    
    lazy var tableHeaderView: UIView = {
        let view = UIStackView(arrangedSubviews: [groupNameLabel])
        view.frame = CGRect(width: 1, height: 100)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableHeaderView = tableHeaderView
        tableView.refreshControl = _refreshControl
        _refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    @objc func refreshData(_: Any) {
        viewModel.fetchArtistGroup()
    }
    
    private enum ArtistGroupDetailItem: Int, CaseIterable {
        case artists, posts
        
        var title: String {
            switch self {
            case .artists: return Strings.ArtistsFieldLabel
            case .posts: return Strings.ArtFieldLabel
            }
        }
        
        func subtitle(forGroup group: ArtistGroup) -> String? {
            switch self {
            case .artists:
                return Strings.CountArtists(group.Artists?.count ?? 0)
            case .posts:
                return Strings.CountPosts(group.Posts?.count ?? 0)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ArtistGroupDetailItem.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let detailItem = ArtistGroupDetailItem(rawValue: indexPath.row)
        cell.textLabel?.text = detailItem?.title
        if let group = viewModel.data {
            cell.detailTextLabel?.text = detailItem?.subtitle(forGroup: group)
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailItem = ArtistGroupDetailItem(rawValue: indexPath.row) else { return }
        guard let group = viewModel.data else { return }

        switch detailItem {
        case .artists:
            let viewModel = DynamicArtistListViewModel(filterForArtistGroup: group, appContext: self.appContext)
            let controller = ArtistListViewController(listTitle: Strings.ArtistGroup_ArtistListTitle(group),
                                                    viewModel: viewModel,
                                                    requestOnLoad: true,
                                                    appContext: appContext)
            navigationController?.pushViewController(controller, animated: true)
        case .posts:
            let viewModel = DynamicPostListViewModel(filterForArtistGroup: self.viewModel.data, appContext: self.appContext)
            let controller = PostListViewController(listTitle: Strings.ArtistGroup_PostListTitle(group),
                                                    viewModel: viewModel,
                                                    requestOnLoad: true,
                                                    appContext: appContext)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
