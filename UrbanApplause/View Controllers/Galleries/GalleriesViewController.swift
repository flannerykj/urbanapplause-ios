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

class GalleriesViewController: UIViewController {
    var appContext: AppContext
    var query: String?
    var collections = [Collection]()
    var galleryListViewModel: GalleryListViewModel
    lazy var galleryListVC = GalleryListViewController_DEP(viewModel: galleryListViewModel,
                                                             appContext: appContext)
    
    init(userId: Int?, appContext: AppContext) {
        self.appContext = appContext
        self.galleryListViewModel = GalleryListViewModel(userId: userId, appContext: appContext)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(galleryListVC.view)
        galleryListVC.view.fill(view: self.view)
        galleryListVC.view.translatesAutoresizingMaskIntoConstraints = false
        galleryListVC.didMove(toParent: self)
        galleryListVC.delegate = self
        addChild(galleryListVC)
        navigationItem.title = Strings.GalleriesTabItemTitle
        
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(createCollection(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func createCollection(_: Any) {
        let vc = NewCollectionViewController(appContext: appContext)
        vc.delegate = galleryListVC
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
}
extension GalleriesViewController: GalleryListDelegate {
    func galleryList(_ controller: GalleryListViewController_DEP,
                     didSelectCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) {
        switch cellModel.gallery {
        case .custom(let collection):
            let vc = TourMapViewController(collection: collection, appContext: appContext)
            navigationController?.pushViewController(vc, animated: true)
        default:
            let vc = GalleryDetailViewController(gallery: cellModel.gallery, appContext: appContext)
            navigationController?.pushViewController(vc, animated: true)
        }
       
    }
    
    func galleryList(_ controller: GalleryListViewController_DEP,
                     accessoryViewForCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) -> UIView? {
        
                return UIImageView(image: UIImage(systemName: "chevron.right"))

    }
}
