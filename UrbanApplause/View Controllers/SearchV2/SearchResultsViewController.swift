//
//  SearchResultsViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-14.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

protocol SearchResultsViewControllerListener: AnyObject {
    func didUpdateSearchQuery(_ query: String?, scopes: [SearchResultSection])
    func didSelectItemAt(indexPath: IndexPath)
}

class SearchResultsViewController: UIViewController, SearchResultsViewControllable, UITableViewDataSource, UITableViewDelegate {
    weak var listener: SearchResultsViewControllerListener?
    private var tableData: [SearchResultSection] = []
    private lazy var loadingView = UIActivityIndicatorView(style: .medium)
    private let appContext: AppContext
    
    private lazy var tableView: UATableView = {
       let tableView = UATableView()
        tableView.register(GalleryCell.self, forCellReuseIdentifier: GalleryCell.ReuseID)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        SearchResultSection.registerCellClasses(forTableView: tableView)
        return tableView
    }()
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - SearchResultsViewControllable
    func updateSearchResults(_ results: [SearchResultSection]) {

        loadingView.stopAnimating()
        tableData = results
        tableView.reloadData()
    }

    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
//        var requestFullScreen = true
//
//        let section = tableData[indexPath.section]
//
//        switch section {
//        case .artists(let artists):
//            let artist = artists[indexPath.row]
//            navigationController?.pushViewController(ArtistProfileViewController(artist: artist, appContext: appContext), animated: true)
//        case .posts(let posts):
//            if let location = posts[indexPath.row].Location {
//                requestFullScreen = false
////                delegate?.searchController(didRequestZoomToLocation: location)
//            }
//        case .locations(let locations):
//            let location = locations[indexPath.row]
//            requestFullScreen = false
////            delegate?.searchController(didRequestZoomToLocation: location)
//        case .groups(let groups):
//            let group = groups[indexPath.row]
//            navigationController?.pushViewController(ArtistGroupDetailViewController(groupID: group.id, group: group, appContext: appContext), animated: true)
//        case .collections(let collections):
//            let collection = collections[indexPath.row]
//            let controller = GalleryDetailViewController(gallery: collection, appContext: appContext)
//            navigationController?.pushViewController(controller, animated: true)
//        case .users(let users):
//            let user = users[indexPath.row]
//            let controller = ProfileViewController(user: user, appContext: appContext)
//            navigationController?.pushViewController(controller, animated: true)
//        }
        
        listener?.didSelectItemAt(indexPath: indexPath)
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        tableData.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = tableData[section]
        switch section {
        case .artists(let artists):
            return artists.count
        case .posts(let posts):
            return posts.count
        case .locations(let locations):
            return locations.count
        case .groups(let groups):
            return groups.count
        case .collections(let collections):
            return collections.count
        case .users(let users):
            return users.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = tableData[section]
        switch section {
        case .artists:
            return "Artists"
        case .posts:
            return "Posts"
        case .locations:
            return "Places"
        case .groups:
            return "Artist Groups"
        case .collections:
            return "Collections"
        case .users:
            return "Users"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = tableData[indexPath.section]
        return section.dequeueAndConfigureCell(tableView: tableView, indexPath: indexPath, appContext: appContext, delegate: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}


extension SearchResultsViewController: SearchResultCellDelegate {
    func postCell(_ cell: PostCell, didUpdatePost post: Post, atIndexPath indexPath: IndexPath) {
        
    }
    
    func postCell(_ cell: PostCell, didSelectUser user: User) {
        
    }
    
    func postCell(_ cell: PostCell, didBlockUser user: User) {
        
    }
    
    func postCell(_ cell: PostCell, didDeletePost post: Post, atIndexPath indexPath: IndexPath) {
        
    }
    
    
}
