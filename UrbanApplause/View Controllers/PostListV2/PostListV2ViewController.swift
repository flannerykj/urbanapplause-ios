//
//  PostListV2ViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2020-12-12.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared
import Combine
import SnapKit


protocol PostListV2ViewControllerDelegate: AnyObject {
    func updateSelectedPosts(_ posts: [Post], indexPaths: [IndexPath])
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath)
}

class PostListV2ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var postListDelegate: PostListV2ViewControllerDelegate?
    private var selectedPosts: [Post] = []
    private let viewModel: PostListViewModel
    private let appContext: AppContext
    
    init(viewModel: PostListViewModel, appContext: AppContext) {
        self.viewModel = viewModel
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var isScrollEnabled: Bool = true {
        didSet {
            collectionView.isScrollEnabled = isScrollEnabled
        }
    }
    private let loadingIndicatorHeight: CGFloat = 24
    
    var contentSizeStream: AnyPublisher<CGSize, Never> {
        return collectionView.contentSizeStream
            .map { (size: CGSize) -> CGSize in
                let height = max(size.height, self.loadingIndicatorHeight)
                return CGSize(width: size.width, height: height)
            }
            .eraseToAnyPublisher()
    }
    
    private let activityIndicator = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        viewModel.didUpdateListItems = { addedIndexPaths, removedIndexPaths, shouldReload in
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
        
        viewModel.didSetErrorMessage = { message in
//            self.updateTableHeader()
        }
        
        viewModel.didSetLoading = { isLoading in
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
        viewModel.fetchListItems(forceReload: false)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        collectionView.allowsMultipleSelection = editing
        let indexPaths = collectionView.indexPathsForVisibleItems
        for indexPath in indexPaths {
            let cell = collectionView.cellForItem(at: indexPath) as! PostV2Cell
            cell.isInEditingMode = editing
        }
    }
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()
    
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
    
    
    // MARK: - UICollectionViewDelegate
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.listItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = viewModel.listItems[indexPath.row]
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
        let cell = collectionView.cellForItem(at: indexPath) as? PostV2Cell
        let post = viewModel.listItems[indexPath.row]

        if isEditing {
            cell?.isSelected = true
            selectedPosts.append(post)
            postListDelegate?.updateSelectedPosts(selectedPosts, indexPaths: collectionView.indexPathsForSelectedItems ?? [])
        } else {
            let thumbImage = cell?.photoView.image
            let vc = PostDetailViewController(postId: post.id,
                                              post: post,
                                              thumbImage: thumbImage,
                                              appContext: appContext)
            vc.delegate = self
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    // MARK: - UICollectionViewDelegateFlowLayout
}

extension PostListV2ViewController: PostDetailDelegate {
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
