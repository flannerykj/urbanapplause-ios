//
//  CollectionViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol CollectionDetailControllerDelegate: class {
    func collectionDetail(didDeleteCollection collection: Collection)
}

class CollectionDetailViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var postListViewModel: PostListViewModel
    var collection: Collection
    weak var delegate: CollectionDetailControllerDelegate?
    
    lazy var postListVC = PostListViewController(viewModel: postListViewModel, mainCoordinator: mainCoordinator)
    
    init(collection: Collection, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.collection = collection
        self.postListViewModel = PostListViewModel(filterForCollection: collection, mainCoordinator: mainCoordinator)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var editButton = UIBarButtonItem(barButtonSystemItem: .edit,
                                          target: self,
                                          action: #selector(editCollection(_:)))
    
    lazy var finishEditingButton = UIBarButtonItem(barButtonSystemItem: .done,
                                                   target: self,
                                                   action: #selector(finishEditing(_:)))
    
    lazy var deleteCollectionButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        button.setTitle("Delete gallery", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = UIColor.backgroundLight
        button.setTitleColor(UIColor.error, for: .normal)
        button.addTarget(self, action: #selector(deleteCollection(_:)), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postListVC.postListDelegate = self
        navigationItem.title = collection.title
        view.addSubview(postListVC.view)
        postListVC.view.translatesAutoresizingMaskIntoConstraints = false
        postListVC.view.fill(view: self.view)
        addChild(postListVC)
        postListVC.didMove(toParent: self)
        
        // navigationItem.rightBarButtonItem = editButton
    }
    
    @objc func editCollection(_: Any) {
        postListVC.tableView.tableFooterView = deleteCollectionButton
        self.postListVC.tableView.setEditing(true, animated: true)
        self.navigationItem.rightBarButtonItem = finishEditingButton
    }
    @objc func finishEditing(_: Any) {
        postListVC.tableView.tableFooterView = nil
        self.postListVC.tableView.setEditing(false, animated: true)
        self.navigationItem.rightBarButtonItem = editButton
    }
    
    @objc func deleteCollection(_: Any) {
        let alertController = UIAlertController(title: "Delete this gallery?",
                                                message: "This cannot be undone",
                                                preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
            indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            indicator.startAnimating()
            alertController.view.addSubview(indicator)
            
            let endpoint = PrivateRouter.deleteCollection(id: self.collection.id)
            _ = self.mainCoordinator.networkService.request(endpoint,
                                                            completion: {(result: UAResult<CollectionContainer>) in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        // self.delegate?.collectionDetail(didDeleteCollection: self.collection)
                        // self.navigationController?.popViewController(animated: true)
                    }
                case .failure(let error):
                    log.error(error)
                }
            })
        })
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        var rect = self.view.frame
        rect.origin.x = self.view.frame.size.width / 20
        rect.origin.y = self.view.frame.size.height / 20
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = rect
        present(alertController, animated: true, completion: nil)
    }
}

extension CollectionDetailViewController: PostListControllerDelegate {
    var canEditPosts: Bool {
        return true
    }
    
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath) {
        self.postListVC.tableView.beginUpdates()
        self.postListVC.viewModel.removePost(atIndex: indexPath.row)
        self.postListVC.tableView.deleteRows(at: [indexPath], with: .automatic)
        self.postListVC.tableView.endUpdates()
        
        let endpoint = PrivateRouter.deleteFromCollection(collectionId: self.collection.id, postId: post.id)
        _ = self.mainCoordinator.networkService.request(endpoint, completion: { (result: UAResult<PostContainer>) in
            switch result {
            case .success:
                break
            case .failure(let error):
                log.error(error)
            }
        })
    }
}