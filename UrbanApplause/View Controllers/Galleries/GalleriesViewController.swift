//
//  CollectionsViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import UrbanApplauseShared

class GalleriesViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var query: String?
    var collections = [Collection]()
    var galleryListViewModel: GalleryListViewModel
    lazy var galleryListVC = GalleryListViewController(viewModel: galleryListViewModel,
                                                             mainCoordinator: mainCoordinator)
    
    init(userId: Int?, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.galleryListViewModel = GalleryListViewModel(userId: userId, mainCoordinator: mainCoordinator)
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
        navigationItem.title = "Galleries"
        
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(createCollection(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func createCollection(_: Any) {
        let vc = NewCollectionViewController(mainCoordinator: mainCoordinator)
        vc.delegate = galleryListVC
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
}
extension GalleriesViewController: GalleryListDelegate {
    func galleryList(_ controller: GalleryListViewController,
                     didSelectCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) {
        
        let vc = GalleryDetailViewController(gallery: cellModel.gallery, mainCoordinator: mainCoordinator)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func galleryList(_ controller: GalleryListViewController,
                     accessoryViewForCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) -> UIView? {
        
                return UIImageView(image: UIImage(systemName: "chevron.right"))

    }
}
