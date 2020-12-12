//
//  CollectionsViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared
import SnapKit

enum GalleryScope: Int, CaseIterable {
    case myCollections
    case publicCollections
    
    var title: String {
        switch self {
        case .publicCollections:
            return "Public"
        case .myCollections:
            return "My collections"
        }
    }
}

class GalleriesViewController: UIViewController, UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    var appContext: AppContext
    var filteredCollections = [Collection]()
    var galleryListViewModel: GalleryListViewModel
    
    private lazy var searchVC: UISearchController = {
        let controller = UISearchController(searchResultsController: nil)
        controller.searchResultsUpdater = self
        controller.searchBar.placeholder = "Search collections"
        controller.delegate = self
        controller.searchBar.delegate = self
        return controller
    }()

    private lazy var searchScopeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: GalleryScope.allCases.map { $0.title })
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(didUpdateSearchScope(_:)), for: .valueChanged)
        return control
    }()
    
    lazy var galleryListVC = GalleriesListViewController(viewModel: galleryListViewModel,
                                                             appContext: appContext)
    
    init(userId: Int?, appContext: AppContext) {
        self.appContext = appContext
        let initialQuery = GalleryQuery(postId: nil, userId: appContext.store.user.data?.id, isPublic: nil, searchQuery: nil)
        self.galleryListViewModel = GalleryListViewModel(userId: userId, appContext: appContext, initialQuery: initialQuery)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        definesPresentationContext = true
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(searchScopeControl)
        view.addSubview(galleryListVC.view)
        
        searchScopeControl.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(44)
        }
        galleryListVC.view.snp.makeConstraints { make in
            make.top.equalTo(searchScopeControl.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        galleryListVC.didMove(toParent: self)
        galleryListVC.delegate = self
        addChild(galleryListVC)
        
        // Setup navigation
        navigationItem.title = Strings.GalleriesTabItemTitle
        navigationItem.searchController = searchVC
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(createCollection(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        updateSearchResults()
        
    }
    @objc func didUpdateSearchScope(_ sender: UISegmentedControl) {
        updateSearchResults()
    }
    @objc func createCollection(_: Any) {
        let vc = NewCollectionViewController(appContext: appContext)
        vc.delegate = galleryListVC
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateSearchResults()
    }
    
    // MARK: - UISearchControllerDelegate

    
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        updateSearchResults()
    }
    
    
    // MARK: - Private
    
    private func updateSearchResults() {
      
        let searchQuery = searchVC.searchBar.text
        guard let scope = GalleryScope.allCases[safe: searchScopeControl.selectedSegmentIndex] else { return }
        var query: GalleryQuery
        
        switch scope {
        case .publicCollections:
            query = GalleryQuery(postId: nil, userId: nil, isPublic: true, searchQuery: searchQuery)
        case .myCollections:
            query = GalleryQuery(postId: nil, userId: appContext.store.user.data?.id, isPublic: nil, searchQuery: searchQuery)
        }
        galleryListViewModel.getData(query: query)
    }
}
extension GalleriesViewController: GalleryListDelegate {
    func galleryList(_ controller: GalleriesListViewController,
                     didSelectCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) {
        switch cellModel.gallery {
        case .custom(let collection):
            let vc = GalleryDetailViewController(gallery: collection, appContext: appContext)
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func galleryList(_ controller: GalleriesListViewController,
                     accessoryViewForCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) -> UIView? {
        
                return UIImageView(image: UIImage(systemName: "chevron.right"))

    }
}
