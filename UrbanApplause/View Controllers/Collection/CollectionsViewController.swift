//
//  CollectionsViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class CollectionsViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var query: String?
    var collections = [Collection]()
    var collectionListViewModel: CollectionListViewModel
    lazy var collectionListVC = CollectionListViewController(viewModel: collectionListViewModel,
                                                             mainCoordinator: mainCoordinator)
    
    init(userId: Int, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.collectionListViewModel = CollectionListViewModel(userId: userId, mainCoordinator: mainCoordinator)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selected = collectionListVC.tableView.indexPathForSelectedRow {
            collectionListVC.tableView.deselectRow(at: selected, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(collectionListVC.view)
        collectionListVC.view.fill(view: self.view)
        collectionListVC.view.translatesAutoresizingMaskIntoConstraints = false
        collectionListVC.didMove(toParent: self)
        collectionListVC.delegate = self
        addChild(collectionListVC)
        navigationItem.title = "Galleries"
        
        let addButton = UIBarButtonItem(image: UIImage(systemName: "plus"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(createCollection(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func createCollection(_: Any) {
        let vc = NewCollectionViewController(mainCoordinator: mainCoordinator)
        vc.delegate = collectionListVC
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
}
extension CollectionsViewController: CollectionListDelegate {
      func collectionList(_ controller: CollectionListViewController,
                          accessoryViewForCollection collection: Collection,
                          at indexPath: IndexPath) -> UIView? {
        return UIImageView(image: UIImage(systemName: "chevron.right"))
    }
    
    func collectionList(_ controller: CollectionListViewController,
                        didSelectCollection collection: Collection,
                        at indexPath: IndexPath) {
        
        let vc = CollectionDetailViewController(collection: collection, mainCoordinator: mainCoordinator)
        navigationController?.pushViewController(vc, animated: true)
    }
}
