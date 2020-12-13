//
//  HomeViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

class SearchPostsViewController: UIViewController {
    var appContext: AppContext
    var postListViewModel: DynamicPostListViewModel
    var searchResultsViewModel: DynamicPostListViewModel
    var postMapViewModel: PostMapViewModel2
    var needsUpdate: Bool = false {
        didSet {
            self.postListViewModel.fetchListItems(forceReload: true)
        }
    }
    
    lazy var postListVC: PostListViewController = PostListViewController(listTitle: Strings.RecentlyAdded_PostListTitle,
                                                                         viewModel: postListViewModel,
                                                                         appContext: appContext)
    
    lazy var searchResultsVC = PostListViewController(viewModel: searchResultsViewModel,
                                                      requestOnLoad: false,
                                                      appContext: appContext)
    
    lazy var searchController: UISearchController = {
        let controller = UISearchController(searchResultsController: searchResultsVC)
        controller.obscuresBackgroundDuringPresentation = false
        controller.delegate = self
        controller.searchBar.delegate = self
        return controller
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Lifecycle
    init(appContext: AppContext) {
        self.appContext = appContext
        self.postListViewModel = DynamicPostListViewModel(filterForPostedBy: nil,
                                                   filterForArtist: nil,
                                                   filterForQuery: nil,
                                                   appContext: appContext)
        
        self.searchResultsViewModel = DynamicPostListViewModel(filterForPostedBy: nil,
                                                    filterForArtist: nil,
                                                    filterForQuery: nil,
                                                    appContext: appContext)
        
        self.postMapViewModel = PostMapViewModel2(appContext: appContext)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        
        // Add list view
        view.addSubview(postListVC.view)
        postListVC.didMove(toParent: self)
        self.addChild(postListVC)
        postListVC.view.translatesAutoresizingMaskIntoConstraints = false
        postListVC.view.fill(view: self.view)
        // Setup navigation bar
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        
        // search bar config
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.autocorrectionType = .no
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

extension SearchPostsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, query.count > 0 else {
            searchController.view.isHidden = true
            return
        }
        searchController.view.isHidden = false
    }
}

extension SearchPostsViewController: UISearchControllerDelegate {
    
}
extension SearchPostsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let query = searchBar.text
        searchResultsViewModel.setSearchQuery(query)
        searchResultsViewModel.fetchListItems(forceReload: true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchResultsViewModel.setSearchQuery(nil)
        searchResultsViewModel.fetchListItems(forceReload: true)
    }
}

extension SearchPostsViewController: CreatePostControllerDelegate {
    func createPostController(_ controller: CreatePostViewController, didDeletePost post: Post) {
        postListViewModel.fetchListItems(forceReload: true)
    }
    
    func createPostController(_ controller: CreatePostViewController, didCreatePost post: Post) {
        
    }
    func createPostController(_ controller: CreatePostViewController, didBeginUploadForData: Data, forPost post: Post, job: NetworkServiceJob?) {
        
    }
    
    func createPostController(_ controller: CreatePostViewController, didUploadImageData: Data, forPost post: Post) {
        
    }
    
}
