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
    var gallery: Collection
    weak var delegate: CollectionDetailControllerDelegate?
    
    private lazy var galleryFooterView: GalleryDetailFooterView = {
        let view = GalleryDetailFooterView()
        view.listener = self
        return view
    }()
    
    lazy var detailsTableView: UITableViewController = {
        let vc = UITableViewController()
        return vc
    }()
    
    
    lazy var postListVC = PostListViewController(viewModel: postListViewModel, appContext: appContext)
    
    init(gallery: Collection, appContext: AppContext) {
        self.appContext = appContext
        self.gallery = gallery
        self.postListViewModel = DynamicPostListViewModel(filterForCollection: gallery,
                                                              appContext: appContext)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var optionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"),
                                             style: .plain,
                                          target: self,
                                          action: #selector(showOptionsMenu(_:)))
    
    lazy var finishEditingButton = UIBarButtonItem(barButtonSystemItem: .done,
                                                   target: self,
                                                   action: #selector(finishEditing(_:)))
    

    override func viewDidLoad() {
        super.viewDidLoad()
        postListVC.postListDelegate = self
        navigationItem.title = gallery.title
        
        view.addSubview(postListVC.view)
        view.addSubview(galleryFooterView)
        postListVC.view.translatesAutoresizingMaskIntoConstraints = false
        postListVC.view.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        galleryFooterView.snp.makeConstraints { make in
            make.top.equalTo(postListVC.view.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        addChild(postListVC)
        postListVC.didMove(toParent: self)
        
        navigationItem.rightBarButtonItem = optionsButton
    }
    
    @objc func showOptionsMenu(_: Any) {
        let optionsModal = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete collection", style: .destructive, handler: { _ in
            optionsModal.dismiss(animated: true, completion: {
                self.confirmDeleteCollection()
            })
        })
        
//        let makePrivatePublicAction = UIAlertAction(title: gallery.is_public ? "Make private" : "Make public" , style: .default, handler: { _ in
//            optionsModal.dismiss(animated: true, completion: {
//
//            })
//        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            optionsModal.dismiss(animated: true, completion: nil)
        })
        
//        optionsModal.addAction(makePrivatePublicAction)
        optionsModal.addAction(deleteAction)
        optionsModal.addAction(cancel)
        
        present(optionsModal, animated: true, completion: nil)
    }
    @objc func finishEditing(_: Any) {
        postListVC.tableView.tableFooterView = nil
        self.postListVC.tableView.setEditing(false, animated: true)
        self.navigationItem.rightBarButtonItem = optionsButton
    }
    
    func confirmDeleteCollection() {
        
        let alertController = UIAlertController(title: Strings.ConfirmDeleteGallery,
                                                message: Strings.IrreversibleActionWarning,
                                                preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: Strings.DeleteButtonTitle, style: .destructive, handler: { _ in
            let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
            indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            indicator.startAnimating()
            alertController.view.addSubview(indicator)
            
            let endpoint = PrivateRouter.deleteCollection(id: self.gallery.id)
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
        self.postListVC.tableView.beginUpdates()
        self.postListVC.viewModel.removeListItem(atIndex: indexPath.row)
        self.postListVC.tableView.deleteRows(at: [indexPath], with: .automatic)
        self.postListVC.tableView.endUpdates()
        
        let endpoint = PrivateRouter.deleteFromCollection(collectionId: gallery.id, postId: post.id)
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
        let vc = TourMapViewController(collection: gallery, appContext: appContext)
        navigationController?.pushViewController(vc, animated: true)
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
