//
//  HomeViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-12.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

class PostListViewModel {
    private var mainCoordinator: MainCoordinator
    
    private let itemsPerPage = 10
    var filterForUser: User?
    var filterForUserApplause: User?
    var filterForArtist: Artist?
    var filterForQuery: String?
    var filterForCollection: Collection?
    var filterForProximity: ProximityFilter?
    var filterForGeoBounds: GeoBoundsFilter?
    var clusterByProximity: Double?
    var showOptionToLoadMore: Bool {
        return !isLoading &&
            posts.count > 0 &&
            posts.count % itemsPerPage == 0 &&
            firstEmptyPage == nil
    }
    private(set) var posts = [Post]()
    private(set) var errorMessage: String? = nil {
        didSet {
            self.didSetErrorMessage?(errorMessage)
        }
    }
    private(set) var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
    
    var didUpdateData: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    
    var currentPage: Int = 0
    var firstEmptyPage: Int?
    
    init(filterForUser: User? = nil,
         filterForUserApplause: User? = nil,
         filterForArtist: Artist? = nil,
         filterForQuery: String? = nil,
         filterForCollection: Collection? = nil,
         mainCoordinator: MainCoordinator) {
        
        self.filterForUser = filterForUser
        self.filterForUserApplause = filterForUserApplause
        self.filterForArtist = filterForArtist
        self.filterForQuery = filterForQuery
        self.filterForCollection = filterForCollection
        self.mainCoordinator = mainCoordinator
    }
    
    func removePost(atIndex index: Int) {
        self.posts.remove(at: index)
    }
    
    func updatePost(atIndex index: Int, updatedPost: Post) {
        self.posts[index] = updatedPost
    }
    
    func getPosts(forceReload: Bool = false) {
        if forceReload {
            self.currentPage = 0
            self.firstEmptyPage = nil
        }
        if firstEmptyPage == currentPage {
            self.isLoading = false
            log.debug("return cuz reached limit")
            return
        }
        guard !isLoading else {
            self.isLoading = false
            log.debug("return cuz already loading")
            return
        }
        isLoading = true
        errorMessage = nil
        _ = mainCoordinator.networkService.request(PrivateRouter.getPosts(page: currentPage,
                                                                      limit: self.itemsPerPage,
                                                                      userId: self.filterForUser?.id,
                                                                      applaudedBy: self.filterForUserApplause?.id,
                                                                      artistId: filterForArtist?.id,
                                                                      search: filterForQuery,
                                                                      collectionId: filterForCollection?.id,
                                                                      proximity: self.filterForProximity,
                                                                      bounds: self.filterForGeoBounds,
                                                                      include: ["applause", "collections", "comments"])
        ) { [weak self] (result: UAResult<PostsContainer>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .failure(let error):
                    self?.errorMessage = error.userMessage
                case .success(let postsContainer):
                    guard self != nil else { log.debug("no self!"); return }
                    if postsContainer.posts.count == 0 {
                        self?.firstEmptyPage = self?.currentPage
                        if !forceReload {
                            return
                        }
                    }
                    let startIndex = self!.posts.count
                    let endIndex = startIndex + postsContainer.posts.count
                    let newIndexPaths = (startIndex ..< endIndex).map { IndexPath(row: $0, section: 0)}
                    if forceReload {
                        self!.posts = postsContainer.posts
                    } else {
                        self?.posts.append(contentsOf: postsContainer.posts)
                    }
                    let shouldReload = self!.currentPage == 0
                    self!.didUpdateData?(newIndexPaths, [], shouldReload)
                    self!.currentPage += 1
                }
            }
            
        }
    }
}
