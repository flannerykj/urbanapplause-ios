//
//  AuthUserDataStream.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-17.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import Shared


protocol PostsStream: AnyObject {
    var homeMapPosts: AnyPublisher<[Post]?, Error> { get }
    var homeMapPostClusters: AnyPublisher<[PostCluster]?, Error> { get }

    var createdPosts: AnyPublisher<[Post]?, Error> { get }
    var applaudedPosts: AnyPublisher<[Post]?, Error> { get }
    var visitedPosts: AnyPublisher<[Post]?, Error> { get }
}

protocol MutablePostsStream: PostsStream {
    func createPost(_ values: [String: Any]) -> AnyPublisher<Post, Error>
    func deletePost(id: Int) -> AnyPublisher<Post, Error>
    func applaudPost(post: Post) -> AnyPublisher<ApplauseInteractionContainer, Error>
    func visitPost(post: Post) -> AnyPublisher<VisitInteractionContainer, Error>
}

class PostsStreamImpl: MutablePostsStream {
    private var cancellables = Set<AnyCancellable>()
    
    private let homeMapPostsSubject = CurrentValueSubject<[Post]?, Error>(nil)
    private let homeMapPostClustersSubject = CurrentValueSubject<[PostCluster]?, Error>(nil)
    private let createdPostsSubject = CurrentValueSubject<[Post]?, Error>(nil)
    private let applaudedPostsSubject = CurrentValueSubject<[Post]?, Error>(nil)
    private let visitedPostsSubject = CurrentValueSubject<[Post]?, Error>(nil)

    private let postsService: PostsAPIService
    private let userStream: UserStream
    
    init(postsService: PostsAPIService, userStream: UserStream) {
        self.postsService = postsService
        self.userStream = userStream
    }
    
    // MARK: UserPostsStream
    var homeMapPosts: AnyPublisher<[Post]?, Error> { homeMapPostsSubject.eraseToAnyPublisher() }
    var homeMapPostClusters: AnyPublisher<[PostCluster]?, Error> { homeMapPostClustersSubject.eraseToAnyPublisher() }
    
    private var userIdStream: AnyPublisher<Int?, Error> {
        userStream.user.map { $0?.id }
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    var createdPosts: AnyPublisher<[Post]?, Error> {
        cache(updateTriggerStream: userIdStream, fetchOperation: { userId in
            return self.postsService.getPosts(query: PostQuery(userId: userId), priority: .primary)
                .map { $0.posts }
                .eraseToAnyPublisher()
        }, cacheSubject: createdPostsSubject)
    }
    
    var applaudedPosts: AnyPublisher<[Post]?, Error> {
        cache(updateTriggerStream: userIdStream, fetchOperation: { userId in
            return self.postsService.getPosts(query: PostQuery(applaudedBy: userId), priority: .primary)
                .map { $0.posts }
                .eraseToAnyPublisher()
        }, cacheSubject: applaudedPostsSubject)
    }
    
    var visitedPosts: AnyPublisher<[Post]?, Error> {
        cache(updateTriggerStream: userIdStream, fetchOperation: { userId in
            return self.postsService.getPosts(query: PostQuery(visitedBy: userId), priority: .primary)
                .map { $0.posts }
                .eraseToAnyPublisher()
        }, cacheSubject: visitedPostsSubject)
    }
    
    // MARK: MutableUserPostsStream
    
    func createPost(_ values: [String: Any]) -> AnyPublisher<Post, Error> {
        return postsService.createPost(values: values, priority: .primary)
            .map { $0.post }
            .handleEvents(receiveOutput: { post in
                self.createdPostsSubject.value?.insert(post, at: 0)
            })
            .eraseToAnyPublisher()
    }
    
    func deletePost(id: Int) -> AnyPublisher<Post, Error> {
        return postsService.deletePost(id: id, priority: .primary)
            .map { $0.post }
            .handleEvents(receiveOutput: { post in
                self.createdPostsSubject.value?.removeAll(where: { $0.id == post.id })
            })
            .eraseToAnyPublisher()
    }
    
    func applaudPost(post: Post) -> AnyPublisher<ApplauseInteractionContainer, Error> {
        return postsService.addOrRemoveClap(postId: post.id, priority: .primary)
            .handleEvents(receiveOutput: { interaction in
                if interaction.deleted {
                    self.applaudedPostsSubject.value?.insert(post, at: 0)
                } else {
                    self.applaudedPostsSubject.value?.removeAll(where: { $0.id == interaction.clap.PostId })
                }
            })
            .eraseToAnyPublisher()
    }
    
    func visitPost(post: Post) -> AnyPublisher<VisitInteractionContainer, Error> {
        return postsService.addOrRemoveVisit(postId: post.id, priority: .primary)
            .handleEvents(receiveOutput: { interaction in
                if interaction.deleted {
                    self.visitedPostsSubject.value?.insert(post, at: 0)
                } else {
                    self.visitedPostsSubject.value?.removeAll(where: { $0.id == interaction.visit.PostId })
                }
            })
            .eraseToAnyPublisher()
    }
    
    // MARK: Private
    private func cache<T, O>(updateTriggerStream: AnyPublisher<T?, Error>,
                             fetchOperation: @escaping (T) -> AnyPublisher<O?, Error>,
                             cacheSubject: CurrentValueSubject<O?, Error>) -> AnyPublisher<O?, Error> {

        if let cachedValue = cacheSubject.value {
            return Just(cachedValue)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return updateTriggerStream
                .flatMap { (triggerData: T?) -> AnyPublisher<O?, Error> in
                    guard let input = triggerData else {
                        return Just(nil)
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()
                    }
                    return fetchOperation(input)
                }
                .eraseToAnyPublisher()
        }
    }
}
