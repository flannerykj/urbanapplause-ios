//
//  CollectionViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

protocol CollectionDetailControllerDelegate: class {
    func collectionDetail(didDeleteCollection collection: Collection)
}

class GalleryDetailViewController: UIViewController {
    var appContext: AppContext
    var postListViewModel: DynamicPostListViewModel
    var gallery: Gallery
    weak var delegate: CollectionDetailControllerDelegate?
    
    lazy var postListVC = PostListViewController(viewModel: postListViewModel, appContext: appContext)
    
    init(gallery: Gallery, appContext: AppContext) {
        self.appContext = appContext
        self.gallery = gallery
        switch gallery {
        case .custom(let collection):
            self.postListViewModel = DynamicPostListViewModel(filterForCollection: collection,
                                                              appContext: appContext)
        case .visits:
            self.postListViewModel = DynamicPostListViewModel(filterForVisitedBy: appContext.store.user.data,
                                                              appContext: appContext)
        case .applause:
            self.postListViewModel = DynamicPostListViewModel(filterForUserApplause: appContext.store.user.data,
                                                              appContext: appContext)
        case .posted:
            self.postListViewModel = DynamicPostListViewModel(filterForPostedBy: appContext.store.user.data,
                                                              appContext: appContext)
        }
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
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
    
    private lazy var footerView: GalleryDetailFooterView = {
        let view = GalleryDetailFooterView()
        view.listener = self
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postListVC.postListDelegate = self
        navigationItem.title = gallery.title
        view.addSubview(postListVC.view)
        postListVC.view.translatesAutoresizingMaskIntoConstraints = false
        postListVC.view.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }
        addChild(postListVC)
        postListVC.didMove(toParent: self)
        
        // navigationItem.rightBarButtonItem = editButton
        
        view.addSubview(footerView)
        footerView.snp.makeConstraints { maker in
            maker.top.equalTo(postListVC.view.snp.bottom)
            maker.bottom.leading.trailing.equalToSuperview()
        }
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
        
        guard case let Gallery.custom(collection) = gallery else { return }
        let alertController = UIAlertController(title: Strings.ConfirmDeleteGallery,
                                                message: Strings.IrreversibleActionWarning,
                                                preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: Strings.DeleteButtonTitle, style: .destructive, handler: { _ in
            let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
            indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            indicator.startAnimating()
            alertController.view.addSubview(indicator)
            
            let endpoint = PrivateRouter.deleteCollection(id: collection.id)
            _ = self.appContext.networkService.request(endpoint,
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

extension GalleryDetailViewController: PostListControllerDelegate {
    var canEditPosts: Bool {
        return true
    }
    
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath) {
        guard case let Gallery.custom(collection) = gallery else { return }
        self.postListVC.tableView.beginUpdates()
        self.postListVC.viewModel.removeListItem(atIndex: indexPath.row)
        self.postListVC.tableView.deleteRows(at: [indexPath], with: .automatic)
        self.postListVC.tableView.endUpdates()
        
        let endpoint = PrivateRouter.deleteFromCollection(collectionId: collection.id, postId: post.id)
        _ = self.appContext.networkService.request(endpoint, completion: { (result: UAResult<PostContainer>) in
            switch result {
            case .success:
                break
            case .failure(let error):
                log.error(error)
            }
        })
    }
}


extension GalleryDetailViewController: GalleryDetailFooterViewDelegate {
    func didTapStartTour() {
        switch gallery {
        case .custom(let collection):
            let vc = TourMapViewController(collection: collection, appContext: appContext)
            navigationController?.pushViewController(vc, animated: true)
        default: break
        }
    }
}


protocol GalleryDetailFooterViewDelegate: AnyObject {
    func didTapStartTour()
}


private class GalleryDetailFooterView: UIView {
    weak var listener: GalleryDetailFooterViewDelegate?
    
    
    
    private lazy var startTourButton: UIButton = {
        let button = UAButton(type: .primary, title: "Start tour", target: self, action: #selector(startTour(_:)), rightImage: UIImage(systemName: "map"))
        return button
    }()
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .systemBackground
        addSubview(startTourButton)
        startTourButton.snp.makeConstraints { maker in
            maker.edges.equalTo(self.safeAreaLayoutGuide).inset(8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func startTour(_: UIButton) {
        listener?.didTapStartTour()
        
    }
    
    
    
}
