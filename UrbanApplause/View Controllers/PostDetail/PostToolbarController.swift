//
//  PostInteractionToolbarView.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import UrbanApplauseShared

protocol PostToolbarDelegate: class {
    func postToolbar(_ toolbar: PostToolbarController, didUpdatePost post: Post)
    func postToolbar(_ toolbar: PostToolbarController, didBlockUser user: User)
    func postToolbar(_ toolbar: PostToolbarController, didDeletePost post: Post)
}

class PostToolbarController: UIViewController {
    weak var delegate: PostToolbarDelegate?
    var mainCoordinator: MainCoordinator?
    var post: Post? {
        didSet {
            applauseCountLabel.text = applauseCountText()
            commentCountLabel.text = commentCountText()
            addedToCollections = post?.Collections ?? []
        }
    }
    var updatingCollections: [Collection] = []
    var addedToCollections: [Collection] = []
    
    lazy var applauseCountLabel = UILabel(type: .body, text: applauseCountText())
    lazy var commentCountLabel = UILabel(type: .body, text: commentCountText())
    
    // lazy var saveCountButton = UIButton(type: .link, title: interactionCountText(type: .save), target: self, onTouchDown: #selector(viewSavedCount(_:)))
    
    // lazy var actionButton = IconButton(image: UIImage(systemName: "square.and.arrow.up"), target: nil, onTouchDown: nil)
    lazy var moreButton = IconButton(image: UIImage(systemName: "ellipsis"),
                                     target: self,
                                     action: #selector(showMoreOptions(_:)))
    
    lazy var stackView: UIStackView = {
        applauseCountLabel.numberOfLines = 1
        commentCountLabel.numberOfLines = 1
        
        let applauseButton = IconButton(image: UIImage(named: "applause"),
                                        size: CGSize(width: 28, height: 28),
                                        target: nil,
                                        action: #selector(applaudPost(_:)))
        
        let applauseStack = UIStackView(arrangedSubviews: [applauseButton, applauseCountLabel])
        applauseStack.axis = .horizontal
        applauseStack.alignment = .center
        applauseStack.translatesAutoresizingMaskIntoConstraints = false
        applauseStack.spacing = 2
        
        let commentButton = IconButton(image: UIImage(systemName: "bubble.right"),
                                       target: self,
                                       action: #selector(pressedComment(_:)))
        let commentStack = UIStackView(arrangedSubviews: [commentButton, commentCountLabel])
        commentStack.axis = .horizontal
        commentStack.alignment = .center
        commentStack.spacing = 2
        commentStack.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [applauseStack,
                                                       commentStack,
                                                       NoFrameView(),
                                                       moreButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = StyleConstants.defaultPaddingInsets
        return stackView
    }()
    
    init(mainCoordinator: MainCoordinator?) {
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
        applauseCountLabel.textColor = UIColor.lightGray
        commentCountLabel.textColor = UIColor.lightGray
        
        view.addSubview(stackView)
        stackView.fill(view: view)
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func savePost() {
        guard let mainCoordinator = self.mainCoordinator, let userId = mainCoordinator.store.user.data?.id else {
            return
        }
        let galleriesViewModel = GalleryListViewModel(userId: userId,
                                                      includeGeneratedGalleries: false,
                                                      mainCoordinator: mainCoordinator)
        
        let vc = GalleryListViewController(viewModel: galleriesViewModel,
                                           mainCoordinator: mainCoordinator)
        vc.navigationItem.title = "Add to galleries"
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    @objc func applaudPost(_ sender: UIButton) {
        toggleApplause()
    }
    
    func blockUser(_ user: User) {
        guard let mainCoordinator = self.mainCoordinator,
            let blockingUser = mainCoordinator.store.user.data else { return }
        let username = user.username ?? "this user"
        let msg = "You will no longer be show posts or comments from this user"
        let alertController = UIAlertController(title: "Block \(username)?", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        let blockAction = UIAlertAction(title: "Block", style: .destructive, handler: { _ in
            let endpoint = PrivateRouter.blockUser(blockingUserId: blockingUser.id, blockedUserId: user.id)
            _ = mainCoordinator.networkService.request(endpoint,
                                                       completion: { (result: UAResult<BlockedUserContainer>) in
                                                        DispatchQueue.main.async {
                                                            switch result {
                                                            case .success:
                                                                self.onBlockUserSuccess(user: user)
                                                            case .failure(let error):
                                                                self.onBlockUserError(error, user: user)
                                                            }
                                                        }
            })
        })
        alertController.addAction(cancelAction)
        alertController.addAction(blockAction)
        presentAlertInCenter(alertController)
        
    }
    
    func onBlockUserSuccess(user: User) {
        self.delegate?.postToolbar(self, didBlockUser: user)
        let username = user.username ?? "This user"
        let successMsg = "\(username) has been blocked"
        let successAlert = UIAlertController(title: successMsg,
                                             message: nil,
                                             preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            successAlert.dismiss(animated: true, completion: nil)
        })
        successAlert.addAction(okAction)
        self.present(successAlert, animated: true, completion: nil)
    }
    
    func onBlockUserError(_ error: UAError, user: User) {
        log.error(error)
        let errorAlert = UIAlertController(title: "Unable to complete request",
                                           message: error.userMessage,
                                           preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            errorAlert.dismiss(animated: true, completion: nil)
        })
        errorAlert.addAction(okAction)
        self.present(errorAlert, animated: true, completion: nil)
    }
    @objc func showMoreOptions(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let savePostAction = UIAlertAction(title: "Save to gallery", style: .default, handler: { _ in
            self.savePost()
        })
        alertController.addAction(savePostAction)
        
        if let mainCoordinator = mainCoordinator,
            let user = mainCoordinator.store.user.data,
            let post = self.post, post.UserId == user.id {
            let deleteAction = UIAlertAction(title: "Delete post", style: .default, handler: { _ in
                self.confirmDeletePost()
            })
            alertController.addAction(deleteAction)
        } else {
            let reportPostAction = UIAlertAction(title: "Report this post", style: .default, handler: { _ in
                self.flagPost()
            })
            let blockActionTitle = "Block \(post?.User?.username ?? "this user")"
            let blockAction = UIAlertAction(title: blockActionTitle, style: .default, handler: { _ in
                guard let user = self.post?.User else { return }
                self.blockUser(user)
            })
            alertController.addAction(reportPostAction)
            alertController.addAction(blockAction)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true, completion: nil)
    }
    
    func confirmDeletePost() {
        guard let mainCoordinator = self.mainCoordinator, let post = self.post else { return }
        
        let alertController = UIAlertController(title: "Are you sure you want to delete this post?",
                                                message: "This cannot be undone.",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            _ = mainCoordinator.networkService.request(PrivateRouter.deletePost(id: post.id),
                                                       completion: { (result: UAResult<PostContainer>) in
                                                        DispatchQueue.main.async {
                                                            switch result {
                                                            case .success:
                                                                self.onDeletePostSuccess(post: post)
                                                            case .failure(let error):
                                                                self.onDeletePostError(error, post: post)
                                                            }
                                                        }
            })
        })
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func onDeletePostSuccess(post: Post) {
        self.delegate?.postToolbar(self, didDeletePost: post)
        let successAlert = UIAlertController(title: "Your post has been deleted.",
                                             message: nil,
                                             preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            successAlert.dismiss(animated: true, completion: nil)
        })
        successAlert.addAction(okAction)
        self.present(successAlert, animated: true, completion: nil)
    }
    func onDeletePostError(_ error: UAError, post: Post) {
        log.error(error)
        let errorAlert = UIAlertController(title: "Unable to complete request",
                                           message: error.userMessage,
                                           preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            errorAlert.dismiss(animated: true, completion: nil)
        })
        errorAlert.addAction(okAction)
        self.present(errorAlert, animated: true, completion: nil)
    }
    func flagPost() {
        guard let store = self.mainCoordinator?.store else { log.debug("no store"); return }
        let vc = ReportAnIssueViewController(store: store) { reportController, reason in
            self.submitFlag(reason: reason, reportAnIssueController: reportController)
        }
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    func applauseCountText() -> String {
        guard let applause = post?.Claps else { return "0" }
        return "\(String(applause.count))"
    }

    func commentCountText() -> String {
        guard let comments = post?.Comments else { return "0" }
        return "\(String(comments.count))"
    }
    
    @objc func viewSavedCount(_: UIButton) {
        // @TODO: view users who've saved / applauded
    }
    
    @objc func pressedComment(_: Any) {
        guard let post = self.post, let mainCoordinator = mainCoordinator else { return }
        let model = CommentListViewModel(post: post, mainCoordinator: mainCoordinator)
        let vc = CommentListViewController(viewModel: model, mainCoordinator: mainCoordinator)
        vc.post = self.post
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func toggleApplause() {
        guard let post = self.post,
            let mainCoordinator = self.mainCoordinator,
            let userId = mainCoordinator.store.user.data?.id else {
                log.error("missing data for creating applause")
                return
        }
        _ = mainCoordinator.networkService.request(PrivateRouter.addOrRemoveClap(postId: post.id, userId: userId),
                                                   completion: { (result: UAResult<ApplauseInteractionContainer>) in
                                                    switch result {
                                                    case .success(let container):
                                                        DispatchQueue.main.async {
                                                            if container.deleted {
                                                                self.post?.Claps?.removeAll { interaction in
                                                                    interaction.id == container.clap.id
                                                                }
                                                            } else {
                                                                self.post?.Claps?.append(container.clap)
                                                            }
                                                            self.delegate?.postToolbar(self, didUpdatePost: post)
                                                            self.applauseCountLabel.text = self.applauseCountText()
                                                            self.view.setNeedsDisplay()
                                                        }
                                                    case .failure(let error):
                                                        log.error(error)
                                                    }
        })
    }
    
    func addPostToCollection(_ collection: Collection, completion: @escaping (Bool) -> Void) {
        guard let post = self.post, let mainCoordinator = self.mainCoordinator else {
            return
        }
        let endpoint = PrivateRouter.addToCollection(collectionId: collection.id, postId: post.id, annotation: "")
        _ = mainCoordinator.networkService.request(endpoint, completion: { (result: UAResult<CollectionContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let container):
                    post.Collections = [container.collection] + (post.Collections ?? [])
                    self.delegate?.postToolbar(self, didUpdatePost: post)
                    completion(true)
                case .failure(let error):
                    log.error(error)
                    completion(false)
                }
            }
        })
    }
    
    func removePostFromCollection(_ collection: Collection, completion: @escaping (Bool) -> Void) {
        guard let post = self.post, let mainCoordinator = self.mainCoordinator else {
            return
        }
        let endpoint = PrivateRouter.deleteFromCollection(collectionId: collection.id, postId: post.id)
        _ = mainCoordinator.networkService.request(endpoint, completion: { (result: UAResult<CollectionContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let container):
                    post.Collections?.removeAll { collection in
                        collection.id == container.collection.id
                    }
                    self.delegate?.postToolbar(self, didUpdatePost: post)
                    completion(true)
                case .failure(let error):
                    log.error(error)
                    completion(false)
                }
            }
        })
    }
    func submitFlag(reason: PostFlagReason, reportAnIssueController: ReportAnIssueViewController) {
        guard let mainCoordinator = self.mainCoordinator, let post = self.post else { return }
        reportAnIssueController.self.isSubmitting = true
        _ = mainCoordinator.networkService.request(PrivateRouter.createPostFlag(postId: post.id,
                                                                                reason: reason),
                                                   completion: { (result: UAResult<PostFlagContainer>) in
                                                    DispatchQueue.main.async {
                                                        reportAnIssueController.self.isSubmitting = false
                                                        switch result {
                                                        case .success(let container):
                                                            log.debug(container)
                                                            reportAnIssueController.didSubmit = true
                                                        case .failure(let error):
                                                            log.error(error)
                                                            reportAnIssueController.handleError(error: error)
                                                        }
                                                    }
        })
    }
}
extension PostToolbarController: GalleryListDelegate {
    func galleryList(_ controller: GalleryListViewController,
                     didSelectCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) {
        
        guard case let Gallery.custom(collection) = cellModel.gallery else { return }
        
        if updatingCollections.firstIndex(where: {
            $0.id == collection.id
        }) != nil {
            return
        }
        
        let updatingIndex = self.updatingCollections.count
        self.updatingCollections.append(collection)
        
        let firstIndex = addedToCollections.firstIndex(where: {
            $0.id == collection.id
        })
        if firstIndex != nil {
            self.removePostFromCollection(collection, completion: { success in
                if success {
                    self.addedToCollections.removeAll(where: {
                        $0.id == collection.id
                    })
                }
                self.updatingCollections.remove(at: updatingIndex)
                controller.reloadGalleryCells([cellModel], animate: true)
            })
        } else {
            self.addPostToCollection(collection, completion: { success in
                if success {
                    self.addedToCollections.append(collection)
                }
                self.updatingCollections.remove(at: updatingIndex)
                controller.reloadGalleryCells([cellModel], animate: true)
            })
        }
        controller.reloadGalleryCells([cellModel], animate: true)
    }
    
    func galleryList(_ controller: GalleryListViewController,
                     accessoryViewForCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) -> UIView? {
        
        if case let Gallery.custom(collection) = cellModel.gallery {
            if updatingCollections.contains(where: {
                $0.id == collection.id
            }) {
                let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                activityIndicator.style = UIActivityIndicatorView.Style.medium
                activityIndicator.startAnimating()
                return activityIndicator
            }
            if addedToCollections.contains(where: {
                $0.id == collection.id
            }) {
                return UIImageView(image: UIImage(systemName: "checkmark"))
            }
        }
        return nil
    }
}

extension PostToolbarController: CommentListDelegate {
    func commentList(didUpdateComments comments: [Comment]) {
        if let post = self.post {
            post.Comments = comments
            delegate?.postToolbar(self, didUpdatePost: post)
            self.commentCountLabel.text = self.commentCountText()
        }
    }
}
