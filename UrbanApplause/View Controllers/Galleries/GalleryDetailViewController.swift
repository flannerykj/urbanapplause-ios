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
    func collectionDetail(didDeletePostsFromCollection collection: Collection)
}

class GalleryDetailViewController: UIViewController {
    private var subscriptions = Set<AnyCancellable>()
    private var selectedPosts: [Post] = [] {
        didSet {
            deleteToolbarItem2.isEnabled = selectedPosts.count > 0

            switch selectedPosts.count {
            case 0:
                selectedItemsToolbarLabel.text = ""
            case 1:
                selectedItemsToolbarLabel.text = "1 post selected"
            default:
                selectedItemsToolbarLabel.text = "\(selectedPosts.count) posts selected"
            }
        }
    }
    
    var appContext: AppContext
    var postListViewModel: DynamicPostListViewModel
    var gallery: Collection
    weak var delegate: CollectionDetailControllerDelegate?
    
//    private lazy var galleryFooterView: GalleryDetailFooterView = {
//        let view = GalleryDetailFooterView()
//        view.listener = self
//        return view
//    }()
    
    lazy var detailsTableView: UITableViewController = {
        let vc = UITableViewController()
        return vc
    }()
    
    
    lazy var postListVC = PostListV2ViewController(viewModel: postListViewModel, appContext: appContext)
    
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
    
    lazy var cancelSelectButton = UIBarButtonItem(title: "Cancel",
                                             style: .plain,
                                          target: self,
                                          action: #selector(finishSelectingPosts(_:)))

    lazy var selectPostsButton = UIBarButtonItem(title: "Select",
                                             style: .plain,
                                          target: self,
                                          action: #selector(startSelectingPosts(_:)))

    private let refreshControl = UIRefreshControl()
    
    private lazy var collectionInfoView = CollectionInfoView()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        // view.refreshControl = refreshControl
        view.alwaysBounceVertical = true
        return view
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        view.backgroundColor = .secondarySystemBackground
        
        setupSubviews()
        setupConstraints()
        
        configureViewForCollection(gallery)
        setUpSelectionToolbar()
        configureForSelectionMode(isSelecting: isEditing)
    }
    
    lazy var deleteToolbarItem2 = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(tappedRemoveSelectedPosts(sender:)))
    let selectedItemsToolbarLabel = UILabel(type: .body, color: .systemBlue)

    private func configureForSelectionMode(isSelecting: Bool) {
        postListVC.setEditing(isSelecting, animated: true)
        navigationController?.setToolbarHidden(!isSelecting, animated: true)

        if isSelecting {
            navigationItem.rightBarButtonItems = [cancelSelectButton]
        } else {
            navigationItem.rightBarButtonItems = [optionsButton, selectPostsButton]
        }
    }
    
    private func setUpSelectionToolbar() {
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [UIBarButtonItem(customView: selectedItemsToolbarLabel), spacer, deleteToolbarItem2]
        selectedItemsToolbarLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        selectedItemsToolbarLabel.numberOfLines = 1
    }
    
    private func setupSubviews() {

        refreshControl.addTarget(self, action: #selector(didPullRefresh(_:)), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
//        view.addSubview(galleryFooterView)
        scrollView.addSubview(postListVC.view)
        scrollView.addSubview(collectionInfoView)
        postListVC.postListDelegate = self
        addChild(postListVC)
        postListVC.didMove(toParent: self)
        postListVC.isScrollEnabled = false
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
        }
//        galleryFooterView.snp.makeConstraints { make in
//            make.top.equalTo(scrollView.snp.bottom)
//            make.leading.trailing.bottom.equalToSuperview()
//        }
        
        collectionInfoView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        postListVC.view.snp.makeConstraints { make in
            make.top.equalTo(collectionInfoView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(0)
        }
        
        postListVC.contentSizeStream
            .sink { size in
                self.postListVC.view.snp.updateConstraints { make in
                    make.height.equalTo(size.height)
                }
                self.postListVC.view.layoutIfNeeded()
            }
            .store(in: &subscriptions)
    }
    
    @objc func didPullRefresh(_ sender: UIRefreshControl) {
        sender.endRefreshing()
        postListViewModel.fetchListItems(forceReload: true)
    }
    
    @objc func startSelectingPosts(_ sender: UIBarButtonItem) {
        configureForSelectionMode(isSelecting: true)
    }
    
    @objc func finishSelectingPosts(_ sender: UIBarButtonItem) {
        configureForSelectionMode(isSelecting: false)
    }
    @objc func showOptionsMenu(_: Any) {
        let optionsModal = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete collection", style: .destructive, handler: { _ in
            optionsModal.dismiss(animated: true, completion: {
                self.confirmDeleteCollection()
            })
        })

        let editAction = UIAlertAction(title: "Edit collection details" , style: .default, handler: { _ in
            optionsModal.dismiss(animated: true, completion: {
                let vc = CollectionFormViewController(existingCollection: self.gallery, appContext: self.appContext)
                vc.delegate = self
                self.present(UANavigationController(rootViewController: vc), animated: true, completion: nil)
            })
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            optionsModal.dismiss(animated: true, completion: nil)
        })
        
        optionsModal.addAction(editAction)
        optionsModal.addAction(deleteAction)
        optionsModal.addAction(cancel)
        
        present(optionsModal, animated: true, completion: nil)
    }
    
    @objc func tappedRemoveSelectedPosts(sender: UIBarButtonItem) {
        let postCountText = selectedPosts.count == 1 ? "1 post" : "\(selectedPosts.count) posts"
        let alertController = UIAlertController(title: "Remove \(postCountText) from collection?",
                                                message: nil,
                                                preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)

        let deleteAction = UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
            let indicator = UIActivityIndicatorView(frame: alertController.view.bounds)
            indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            indicator.startAnimating()
            alertController.view.addSubview(indicator)
            
            let endpoint = PrivateRouter.updateCollectionPosts(collectionId: self.gallery.id, postsIdsToAdd: [], postIdsToRemove: self.selectedPosts.map { $0.id })
            _ = self.appContext.networkService.request(endpoint,
                                                       completion: {(result: UAResult<CollectionContainer>) in
                                                        switch result {
                                                        case .success(let container):
                                                            DispatchQueue.main.async {
                                                                self.configureForSelectionMode(isSelecting: false)
                                                                self.postListViewModel.fetchListItems(forceReload: true)
                                                                self.delegate?.collectionDetail(didDeletePostsFromCollection: self.gallery)
                                                            }
                                                        case .failure(let error):
                                                            log.error(error)
                                                            self.showAlert(title: "Unable to remove posts", message: "Didn't work. Not at all. totally failed.", onDismiss: nil)
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
                                                        case .success(let container):
                                                            DispatchQueue.main.async {
                                                                self.delegate?.collectionDetail(didDeleteCollection: container.collection)
                                                                self.navigationController?.popViewController(animated: true)
                                                            }
                                                        case .failure(let error):
                                                            log.error(error)
                                                            self.showAlert(title: "Unable to delete collection", message: "Didn't work. not sure why. ", onDismiss: nil)
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
    
    private func configureViewForCollection(_ collection: Collection) {
        collectionInfoView.updateForCollection(collection)
        self.gallery = collection
        self.navigationItem.title = collection.title
    }
}

extension GalleryDetailViewController: PostListV2ViewControllerDelegate {
    func updateSelectedPosts(_ posts: [Post], indexPaths: [IndexPath]) {
        self.selectedPosts = posts
    }
    
    var canEditPosts: Bool {
        return true
    }
    
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath) {
//        self.postListVC.tableView.beginUpdates()
//        self.postListVC.viewModel.removeListItem(atIndex: indexPath.row)
//        self.postListVC.tableView.deleteRows(at: [indexPath], with: .automatic)
//        self.postListVC.tableView.endUpdates()
//        
//        let endpoint = PrivateRouter.deleteFromCollection(collectionId: gallery.id, postId: post.id)
//        _ = self.appContext.networkService.request(endpoint, completion: { (result: UAResult<PostContainer>) in
//            switch result {
//            case .success:
//                break
//            case .failure(let error):
//                log.error(error)
//            }
//        })
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
        backgroundColor = .secondarySystemBackground
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
    private let descriptionLabel = UILabel(type: .body)
    private let visibilityStatusLabel = UILabel(type: .small)
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [descriptionLabel, visibilityStatusLabel])
        view.axis = .vertical
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 0, left: StyleConstants.contentMargin, bottom: StyleConstants.contentMargin, right: StyleConstants.contentMargin)
        view.spacing = 8
        return view
    }()
    
    
    func updateForCollection(_ collection: Collection) {
        visibilityStatusLabel.text = collection.is_public ? "Public" : "Private"
        descriptionLabel.text = collection.description
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


extension GalleryDetailViewController: NewCollectionViewControllerDelegate {
    func didCreateCollection(collection: Collection) {
        log.error("Detail view doesn't handle creating new collections")
    }
    
    func didUpdateCollection(collection: Collection) {
        configureViewForCollection(collection)
    }
}
