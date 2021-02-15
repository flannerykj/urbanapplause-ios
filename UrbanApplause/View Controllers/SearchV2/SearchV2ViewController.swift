//
//  SearchV2ViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-14.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

fileprivate enum SearchResultsScope {
    case all
    case one(SearchResultSection)
    
    static var allCases: [SearchResultsScope] {
       [ .all ] + SearchResultSection.allCases.map { .one($0) }
    }
    
    var searchResultSections: [SearchResultSection] {
        switch self {
        case .all:
            return SearchResultSection.allCases
        case .one(let searchResultSection):
            return [searchResultSection]
        }
    }
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case .one(let sectionType):
            return sectionType.title
        }
    }
}
protocol SearchV2ViewControllerListener: AnyObject {
    func searchV2Controller(_ controller: SearchV2ViewController, didSelectLocation location: Location)
}

class SearchV2ViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate {
    weak var listener: SearchV2ViewControllerListener?
    
    public var searchBar: UISearchBar {
        searchVC.searchBar
    }
    private let appContext: AppContext
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var searchVC: UISearchController = {
        let controller = UISearchController(searchResultsController: galleryListVC)
        controller.searchResultsUpdater = self
        controller.searchBar.placeholder = "Search for artists, users, places etc"
        controller.delegate = self
        controller.searchBar.autocapitalizationType = .none
        controller.searchBar.delegate = self
//        controller.searchBar.scopeButtonTitles = SearchResultsScope.allCases.map { $0.title }
        return controller
    }()
    
    private lazy var galleryListVC: SearchResultsViewController = {
        SearchResultsViewController(appContext: appContext)
    }()
    
    private lazy var galleryResultsInteractor = SearchResultsInteractor(appContext: appContext, viewControllable: galleryListVC)

    private lazy var closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(tappedClose(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        galleryResultsInteractor.listener = self
        galleryListVC.listener = galleryResultsInteractor
       
        view.backgroundColor = UIColor.secondarySystemBackground

        // Setup navigation
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.title = Strings.SearchTabItemTitle
        navigationItem.searchController = searchVC
        navigationItem.rightBarButtonItem = closeButton
        definesPresentationContext = true
        
        updateSearchResults()
        searchVC.searchBar.becomeFirstResponder()
    }
    
    @objc func tappedClose(_: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UISearchControllerDelegate

    
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        updateSearchResults()
    }
    
    
    // MARK: - Private
    
    private func updateSearchResults() {
        let searchQuery = searchVC.searchBar.text
        galleryResultsInteractor.didUpdateSearchQuery(searchQuery, scopes: SearchResultSection.allCases)
        
    }
}
extension SearchV2ViewController: SearchResultsListener {
    func didSelectItem(inSection section: SearchResultSection, at row: Int) {
        var detailController: UIViewController?
        
        switch section {
        case .artists(let artists):
            let artist = artists[row]
            detailController = ArtistProfileViewController(artist: artist, appContext: appContext)
        case .collections(let collections):
            let collection = collections[row]
            detailController = GalleryDetailViewController(gallery: collection, appContext: appContext)
        case .groups(let groups):
            let group = groups[row]
            detailController = ArtistGroupDetailViewController(groupID: group.id, group: group, appContext: appContext)
        case .locations(let locations):
            listener?.searchV2Controller(self, didSelectLocation: locations[row])
        case .posts(let posts):
            let post = posts[row]
            detailController = PostDetailViewController(postId: post.id, post: post, appContext: appContext)
        case .users(let users):
            let user = users[row]
            detailController = ProfileViewController(user: user, appContext: appContext)
        }
        if let controller = detailController {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
