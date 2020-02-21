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
    private var postQuery: PostQuery
    var clusterByProximity: Double?
    
    override var showOptionToLoadMore: Bool {
        return !isLoading &&
            listItems.count > 0 &&
            listItems.count % postQuery.limit == 0 &&
            firstEmptyPage == nil
    }
    
    override var currentPage: Int {
        set {
            postQuery.page = newValue
        }
        get {
            return postQuery.page
        }
    }

    var firstEmptyPage: Int?
    
    init(filterForPostedBy: User? = nil,
         filterForVisitedBy: User? = nil,
         filterForUserApplause: User? = nil,
         filterForArtist: Artist? = nil,
         filterForArtistGroup: ArtistGroup? = nil,
         filterForQuery: String? = nil,
         filterForCollection: Collection? = nil,
         appContext: AppContext) {
        
        let postQuery = PostQuery(page: 0,
                                  limit: 10,
                                  userId: filterForPostedBy?.id,
                                  applaudedBy: filterForUserApplause?.id,
                                  visitedBy: filterForVisitedBy?.id,
                                  artistId: filterForArtist?.id,
                                  artistGroupId: filterForArtistGroup?.id,
                                  search: filterForQuery,
                                  collectionId: filterForCollection?.id,
                                  proximity: nil,
                                  bounds: nil,
                                  include: Post.includeParams)
        
        self.postQuery = postQuery
        super.init(posts: [], appContext: appContext)
    }
    
    override func fetchListItems(forceReload: Bool = false) {
        if forceReload {
            self.postQuery.page = 0
            self.firstEmptyPage = nil
        }
        if firstEmptyPage == postQuery.page {
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
                        self?.firstEmptyPage = self?.postQuery.page
                        if !forceReload {
                            return
                        }
                    }
                    
                    if forceReload {
                        self!._listItems = postsContainer.posts
                    } else {
                        self?._listItems.append(contentsOf: postsContainer.posts)
                    }
                    let shouldReload = self!.postQuery.page == 0
                    self!.didUpdateListItems?(self!.getNewIndexPaths(forAddedItems: postsContainer.posts), [], shouldReload)
                    self!.postQuery.page += 1
                }
            }
        }
    }
    
    public func setSearchQuery(_ query: String?) {
        self.postQuery.search = query
    }
}
