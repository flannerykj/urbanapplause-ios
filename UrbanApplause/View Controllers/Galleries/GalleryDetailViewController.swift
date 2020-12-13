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

class GalleryDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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

    private let activityIndicator = UIActivityIndicatorView()
    
    private lazy var collectionInfoView = CollectionInfoView()
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()
    private let loadingIndicatorHeight: CGFloat = 24

    private lazy var collectionView: UACollectionView = {
        let view = UACollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.register(PostV2Cell.self, forCellWithReuseIdentifier: "PostV2Cell")
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        return view
    }()
    
    private lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        // view.refreshControl = refreshControl
        view.alwaysBounceVertical = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        
        setupSubviews()
        setupConstraints()
        
        configureViewForCollection(gallery)
        configureForSelectionMode(isSelecting: isEditing)
        

        postListViewModel.didUpdateListItems = { addedIndexPaths, removedIndexPaths, shouldReload in
            DispatchQueue.main.async {
                if shouldReload {
                    self.collectionView.reloadData()
                } else {
                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: removedIndexPaths)
                        self.collectionView.insertItems(at: addedIndexPaths)
                    }, completion: { _ in
//                        self.updateTableHeader()
//                        self.updateTableFooter()
                    })
                }

            }
        }
        
        postListViewModel.didSetErrorMessage = { message in
//            self.updateTableHeader()
        }
        
        postListViewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.isHidden = false
                } else {
                    self.activityIndicator.isHidden = true
                    self.activityIndicator.stopAnimating()
                }
            }
        }
        activityIndicator.startAnimating()
        postListViewModel.fetchListItems(forceReload: false)
    }
    
    private func configureForSelectionMode(isSelecting: Bool) {
        if isSelecting {
            navigationItem.rightBarButtonItems = [cancelSelectButton]
        } else {
            navigationItem.rightBarButtonItems = [optionsButton, selectPostsButton]
        }
    }
    
    private func setupSubviews() {
//        refreshControl.addTarget(self, action: #selector(didPullRefresh(_:)), for: .valueChanged)
        
        view.addSubview(scrollView)
        view.addSubview(galleryFooterView)
        
        scrollView.addSubview(collectionInfoView)
        scrollView.addSubview(collectionView)
        
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
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(collectionInfoView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(0)
        }
        
        collectionView.contentSizeStream
            .map { (size: CGSize) -> CGSize in
                let height = max(size.height, self.loadingIndicatorHeight)
                return CGSize(width: size.width, height: height)
            }
            .sink { size in
                print("height: ", size.height)
                self.collectionView.snp.updateConstraints { make in
                    make.height.equalTo(size.height)
                }
                self.collectionView.layoutIfNeeded()
            }
            .store(in: &subscriptions)
    }
    
//    @objc func didPullRefresh(_ sender: UIRefreshControl) {
//        postListViewModel.fetchListItems(forceReload: true)
//    }
//
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
    
    // MARK: - UICollectionViewDelegate
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return postListViewModel.listItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = postListViewModel.listItems[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostV2Cell", for: indexPath) as! PostV2Cell
        if let firstFile = post.PostImages?.first {
            if let thumb = firstFile.thumbnail {
                let imageJob = appContext.fileCache.getJobForFile(thumb, isThumb: true)
                cell.downloadJob = imageJob
            } else {
                let imageJob = appContext.fileCache.getJobForFile(firstFile, isThumb: true)
                cell.downloadJob = imageJob
            }
        }
        cell.appContext = appContext
        cell.post = post
        cell.indexPath = indexPath
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width/4
        return CGSize(width: width, height: width)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if isEditing {
            
        } else {
            let post = postListViewModel.listItems[indexPath.row]
            let cell = collectionView.cellForItem(at: indexPath) as? PostV2Cell
            let thumbImage = cell?.photoView.image
            let vc = PostDetailViewController(postId: post.id,
                                              post: post,
                                              thumbImage: thumbImage,
                                              appContext: appContext)
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

extension GalleryDetailViewController: PostListControllerDelegate {
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
    private let descriptionLabel = UILabel(type: .body)

    
//    private let isPublicControl = UISwitch()
//
//    private lazy var isPublicView: UIView = {
//        let label = UILabel(type: .small, text: "Is public")
//        let view = UIView()
//        view.addSubview(label)
//        view.addSubview(isPublicControl)
//        label.snp.makeConstraints { make in
//            make.top.leading.bottom.equalToSuperview()
//        }
//        isPublicControl.snp.makeConstraints { make in
//            make.top.trailing.bottom.equalToSuperview()
//            make.leading.equalTo(label.snp.trailing).offset(8)
//        }
//        return view
//    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        view.axis = .vertical
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: StyleConstants.contentMargin, left: StyleConstants.contentMargin, bottom: StyleConstants.contentMargin, right: StyleConstants.contentMargin)
        view.spacing = 8
        return view
    }()
    
    
    func updateForCollection(_ collection: Collection) {
        titleLabel.text = collection.title
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
extension GalleryDetailViewController: PostDetailDelegate {
    func postDetail(_ controller: PostDetailViewController, didUpdatePost post: Post) {
        
    }
    
    func postDetail(_ controller: PostDetailViewController, didBlockUser user: User) {
        
    }
    
    func postDetail(_ controller: PostDetailViewController, didDeletePost post: Post) {
        
    }
    
    
}
class UACollectionView: UICollectionView {
    public var contentSizeStream: AnyPublisher<CGSize, Never> {
        contentSizeSubject.eraseToAnyPublisher()
    }
    
    private let contentSizeSubject = CurrentValueSubject<CGSize, Never>(.zero)
    
    override var contentSize: CGSize {
        didSet {
            contentSizeSubject.value = contentSize
        }
    }
}
