//
//  HomeViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class SearchPostsViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var postListViewModel: DynamicPostListViewModel
    var searchResultsViewModel: DynamicPostListViewModel
    var postMapViewModel: PostMapViewModel2
    var needsUpdate: Bool = false {
        didSet {
            self.postListViewModel.getPosts(forceReload: true)
        }
    }
    
    lazy var postListVC: PostListViewController = PostListViewController(listTitle: "Recently added",
                                                                         viewModel: postListViewModel,
                                                                         mainCoordinator: mainCoordinator)
    
    lazy var searchResultsVC = PostListViewController(viewModel: searchResultsViewModel,
                                                      requestOnLoad: false,
                                                      mainCoordinator: mainCoordinator)
    
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
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.postListViewModel = DynamicPostListViewModel(filterForPostedBy: nil,
                                                   filterForArtist: nil,
                                                   filterForQuery: nil,
                                                   mainCoordinator: mainCoordinator)
        
        self.searchResultsViewModel = DynamicPostListViewModel(filterForPostedBy: nil,
                                                    filterForArtist: nil,
                                                    filterForQuery: nil,
                                                    mainCoordinator: mainCoordinator)
        
        self.postMapViewModel = PostMapViewModel2(mainCoordinator: mainCoordinator)
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

extension SearchPostsViewController: PostFormDelegate {
    func didCreatePost(post: Post) {
        postListViewModel.getPosts(forceReload: true)
    }
    
    func didDeletePost(post: Post) {
        postListViewModel.getPosts(forceReload: true)
    }
}
