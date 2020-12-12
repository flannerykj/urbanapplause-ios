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
import Combine

protocol CollectionDetailControllerDelegate: class {
    func collectionDetail(didDeleteCollection collection: Collection)
}

class GalleryDetailViewController: UIViewController {
    private var subscriptions = Set<AnyCancellable>()
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
    private let refreshControl = UIRefreshControl()
    
    private lazy var collectionInfoView = CollectionInfoView()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        // view.refreshControl = refreshControl
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = gallery.title
        
        setupSubviews()
        setupConstraints()
        
        navigationItem.rightBarButtonItem = optionsButton
        collectionInfoView.updateForCollection(gallery)
    }
    
    private func setupSubviews() {
//        refreshControl.addTarget(self, action: #selector(didPullRefresh(_:)), for: .valueChanged)
        
        view.addSubview(scrollView)
        view.addSubview(galleryFooterView)
        scrollView.addSubview(postListVC.view)
        scrollView.addSubview(collectionInfoView)
        postListVC.postListDelegate = self
        addChild(postListVC)
        postListVC.didMove(toParent: self)
        postListVC.tableView.isScrollEnabled = false
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        galleryFooterView.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        collectionInfoView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        postListVC.view.snp.makeConstraints { make in
            make.top.equalTo(collectionInfoView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(0)
        }
        
        postListVC.tableView.contentSizeStream
            .sink { size in
                print("height: ", size.height)
                self.postListVC.view.snp.updateConstraints { make in
                    make.height.equalTo(size.height)
                }
                self.postListVC.view.layoutIfNeeded()
            }
            .store(in: &subscriptions)
        
        
        
        
    }
    
//    @objc func didPullRefresh(_ sender: UIRefreshControl) {
//        postListViewModel.fetchListItems(forceReload: true)
//    }
//
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


fileprivate class CollectionInfoView: UIView {
    private let titleLabel = UILabel(type: .h3)
    
    
    private let isPublicControl = UISwitch()
    
    private lazy var isPublicView: UIView = {
        let label = UILabel(type: .small, text: "Is public")
        let view = UIView()
        view.addSubview(label)
        view.addSubview(isPublicControl)
        label.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
        }
        isPublicControl.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(label.snp.trailing).offset(8)
        }
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabel, isPublicView])
        view.axis = .vertical
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: StyleConstants.contentMargin, left: StyleConstants.contentMargin, bottom: StyleConstants.contentMargin, right: StyleConstants.contentMargin)
        view.spacing = 8
        return view
    }()
    
    
    func updateForCollection(_ collection: Collection) {
        titleLabel.text = collection.title
        isPublicControl.isOn = collection.is_public
    }
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
