//
//  HomeViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-12.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit
import Shared

class DynamicPostListViewModel: PostListViewModel {
    private var appContext: AppContext
    
    private let itemsPerPage = 10
    
    var filterForVisitedBy: User?
    var filterForPostedBy: User?
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
    internal var _posts = [Post]()
    var errorMessage: String? = nil {
        didSet {
            self.didSetErrorMessage?(errorMessage)
        }
    }
    var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
    
    var didUpdateData: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    
    var currentPage: Int = 0
    var firstEmptyPage: Int?
    
    init(filterForPostedBy: User? = nil,
         filterForVisitedBy: User? = nil,
         filterForUserApplause: User? = nil,
         filterForArtist: Artist? = nil,
         filterForQuery: String? = nil,
         filterForCollection: Collection? = nil,
         appContext: AppContext) {
        
        self.filterForPostedBy = filterForPostedBy
        self.filterForVisitedBy = filterForVisitedBy
        self.filterForUserApplause = filterForUserApplause
        self.filterForArtist = filterForArtist
        self.filterForQuery = filterForQuery
        self.filterForCollection = filterForCollection
        self.appContext = appContext
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
        let postQuery = PostQuery(page: currentPage,
                                limit: self.itemsPerPage,
                                userId: self.filterForPostedBy?.id,
                                applaudedBy: self.filterForUserApplause?.id,
                                visitedBy: self.filterForVisitedBy?.id,
                                artistId: filterForArtist?.id,
                                search: filterForQuery,
                                collectionId: filterForCollection?.id,
                                proximity: self.filterForProximity,
                                bounds: self.filterForGeoBounds,
                                include: ["claps", "collections", "comments", "visits"])
        _ = appContext.networkService.request(PrivateRouter.getPosts(query: postQuery)
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
                    
                    if forceReload {
                        self!._posts = postsContainer.posts
                    } else {
                        self?._posts.append(contentsOf: postsContainer.posts)
                    }
                    let shouldReload = self!.currentPage == 0
                    self!.didUpdateData?(self!.getNewIndexPaths(forAddedPosts: postsContainer.posts), [], shouldReload)
                    self!.currentPage += 1
                }
            }
        }
    }
}
