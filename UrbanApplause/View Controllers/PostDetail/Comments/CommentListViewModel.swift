//
//  CommentListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

class CommentListViewModel {
    private var mainCoordinator: MainCoordinator
    private var post: Post?
    
    private(set) var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
    private(set) var isSubmitting = false {
        didSet {
            self.didSetSubmitting?(isSubmitting)
        }
    }

    private(set) var comments = [Comment]()
    
    private(set) var errorMessage: String? = nil {
        didSet {
            self.didSetErrorMessage?(errorMessage)
        }
    }
    
    var didUpdateData: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetSubmitting: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    var didDeleteComment: ((Comment) -> Void)?
    var didCreateComment: ((Comment) -> Void)?
    var didBlockUser: ((User) -> Void)?
    
    init(post: Post?, mainCoordinator: MainCoordinator) {
        self.post = post
        self.mainCoordinator = mainCoordinator
    }
    
    func setPost(_ post: Post?) {
        self.post = post
        getComments()
    }
    
    func getComments() {
        guard !isLoading, let postId = post?.id else {
            return
        }
        errorMessage = nil
        isLoading = true
        let endpoint = PrivateRouter.getComments(postId: postId)
        _ = mainCoordinator.networkService.request(endpoint) { [weak self] (result: UAResult<CommentsContainer>) in
            
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.errorMessage = error.userMessage
                case .success(let commentsContainer):
                    log.debug("success! \(commentsContainer)")
                    self?.comments = commentsContainer.comments.sorted(by: {
                        $0.createdAt < $1.createdAt
                    })
                    self?.didUpdateData?([], [], true)
                }
            }
        }
    }
    
    func submitComment(contents: String?) {
        guard !isSubmitting, let postId = post?.id else {
            return
        }
        guard let content = contents else {
            errorMessage = "Comment cannot be empty"
            return
        }
        guard let user = mainCoordinator.store.user.data else {
            log.error("no user set")
            return
        }
        self.errorMessage = nil
        self.isSubmitting = true
        _ = mainCoordinator.networkService.request(PrivateRouter.createComment(postId: postId,
                                                                                   userId: user.id,
                                                                                   content: content),
                                                       completion: { (result: UAResult<CommentContainer>) in
            self.isSubmitting = false
            switch result {
            case .success(let container):
                let comment = container.comment
                comment.User = user
                self.comments.append(comment)
                self.didCreateComment?(comment)
                self.didUpdateData?([IndexPath(row: self.comments.count - 1, section: 0)], [], false)
            case .failure(let error):
                log.error(error)
                self.errorMessage = error.userMessage
            }
        })
    }
    
    func deleteComment(_ comment: Comment, at indexPath: IndexPath) {
        _ = self.mainCoordinator.networkService.request(PrivateRouter.deleteComment(commentId: comment.id),
                                                        completion: { (result: UAResult<CommentContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.comments.remove(at: indexPath.row)
                    self.didUpdateData?([], [indexPath], false)
                    self.didDeleteComment?(comment)
                case .failure(let error):
                    self.errorMessage = error.userMessage
                }
            }
        })
    }
    
    func blockUser(_ user: User) {
        guard let blockingUser = mainCoordinator.store.user.data else { return }
        _ = self.mainCoordinator.networkService.request(PrivateRouter.blockUser(blockingUserId: blockingUser.id,
                                                                                blockedUserId: user.id),
                                                        completion: { (result: UAResult<BlockedUserContainer>) in
            switch result {
            case .success:
                self.didBlockUser?(user)
            case .failure(let error):
                self.errorMessage = error.userMessage
            }
        })
    }
    
    func flagComment(_ comment: Comment) {
        
    }
}
