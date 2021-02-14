//
//  SearchViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-13.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared
import SnapKit
import FloatingPanel

protocol SearchViewControllerDelegate: AnyObject {
    
}

protocol SearchViewControllable: AnyObject {
    var scrollingView: UIScrollView { get }
    func updateSearchResults(_ results: [SearchResultSection])
}

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SearchViewControllable, SearchResultCellDelegate {

    private var bgColor: UIColor {
        .tertiarySystemBackground
    }
    
    weak var delegate: SearchViewControllerDelegate?
    weak var searchInteractable: SearchInteractable?
    
    private let appContext: AppContext
    
    private var tableData: [SearchResultSection] = []
    private lazy var loadingView = UIActivityIndicatorView(style: .medium)
    

    private lazy var searchView = SearchResultsTableHeaderView(bgColor: bgColor)

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = bgColor
        SearchResultSection.registerCellClasses(forTableView: tableView)
        return tableView
    }()
    
    private var searchBar: UISearchBar {
        searchView.searchBar
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIViewController Lifecycle
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bgColor
        searchView.searchBar.delegate = self

        view.addSubview(searchView)
        view.addSubview(tableView)
        searchBar.addSubview(loadingView)

        searchView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        loadingView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(120)
        }
        loadingView.hidesWhenStopped = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - SearchViewControllable
    var scrollingView: UIScrollView {
        tableView
    }
    
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
        var requestFullScreen = true
        
        let section = tableData[indexPath.section]
        
        switch section {
        case .artists(let artists):
            let artist = artists[indexPath.row]
            navigationController?.pushViewController(ArtistProfileViewController(artist: artist, appContext: appContext), animated: true)
        case .posts(let posts):
            if let location = posts[indexPath.row].Location {
                requestFullScreen = false
//                delegate?.searchController(didRequestZoomToLocation: location)
            }
        case .locations(let locations):
            let location = locations[indexPath.row]
            requestFullScreen = false
//            delegate?.searchController(didRequestZoomToLocation: location)
        case .groups(let groups):
            let group = groups[indexPath.row]
            navigationController?.pushViewController(ArtistGroupDetailViewController(groupID: group.id, group: group, appContext: appContext), animated: true)
        case .collections(let collections):
            let collection = collections[indexPath.row]
            let controller = GalleryDetailViewController(gallery: collection, appContext: appContext)
            navigationController?.pushViewController(controller, animated: true)
        case .users(let users):
            let user = users[indexPath.row]
            let controller = ProfileViewController(user: user, appContext: appContext)
            navigationController?.pushViewController(controller, animated: true)
        }
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
        searchBar.endEditing(true)
    }
    
    // MARK: - UISearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        refreshSearchResults()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    private func refreshSearchResults() {
        guard let text = searchBar.text, !text.isEmpty else {
            updateSearchResults([])
            return
        }
        loadingView.startAnimating()
        searchInteractable?.fetchContent(forQuery: text)
    }
    
    
    // MARK: - SearchResultCellDelegate
    
    // MARK: - PostCellDelegate
    func postCell(_ cell: PostCell, didUpdatePost post: Post, atIndexPath indexPath: IndexPath) {
        refreshSearchResults()
    }
    
    func postCell(_ cell: PostCell, didSelectUser user: User) {
        let controller = ProfileViewController(user: user, appContext: appContext)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func postCell(_ cell: PostCell, didBlockUser user: User) {
        refreshSearchResults()
    }
    
    func postCell(_ cell: PostCell, didDeletePost post: Post, atIndexPath indexPath: IndexPath) {
        refreshSearchResults()
    }
    
    // MARK: UITraitEnvironment
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//        view.backgroundColor = UIColor.secondarySystemBackground
    }
}


class SearchResultsTableHeaderView: UIView {
    private let bgColor: UIColor
    
    fileprivate lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.layer.borderWidth = 1
        searchBar.barStyle = .black
        searchBar.backgroundImage = UIImage()
        searchBar.barTintColor = .secondarySystemBackground
        searchBar.layer.borderColor = bgColor.cgColor
        searchBar.showsCancelButton = true
        searchBar.returnKeyType = .done
        return searchBar
    }()
    
    init(bgColor: UIColor) {
        self.bgColor = bgColor
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(44)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: UITraitEnvironment
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        searchBar.layer.borderColor = bgColor.cgColor
    }
}
