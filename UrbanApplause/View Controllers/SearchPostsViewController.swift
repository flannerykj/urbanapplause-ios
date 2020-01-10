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
            self.postListViewModel.getPosts(forceReload: true)
        }
    }
    
    lazy var postListVC: PostListViewController = PostListViewController(listTitle: Strings.RecentlyAddedPostListTitle,
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
        view.backgroundColor = UIColor.backgroundMain
        
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
        searchResultsViewModel.filterForQuery = query
        searchResultsViewModel.getPosts(forceReload: true)
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchResultsViewModel.filterForQuery = nil
        searchResultsViewModel.getPosts(forceReload: true)
    }
}

extension SearchPostsViewController: CreatePostControllerDelegate {
    func didCreatePost(post: Post) {
        // wait for upload images to complete
    }
    
    func didCompleteUploadingImages(post: Post) {
        postListViewModel.getPosts(forceReload: true)
    }
    
    func didDeletePost(post: Post) {
        postListViewModel.getPosts(forceReload: true)
    }
}
