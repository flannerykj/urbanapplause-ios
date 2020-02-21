//
//  DynamicArtistListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

class DynamicArtistListViewModel: ArtistListViewModel {
    private var artistQuery: ArtistQuery
    
    var clusterByProximity: Double?
    
    override var showOptionToLoadMore: Bool {
        return !isLoading &&
            listItems.count > 0 &&
            listItems.count % artistQuery.limit == 0 &&
            firstEmptyPage == nil
    }
    override var currentPage: Int {
        set {
            artistQuery.page = newValue
        }
        get {
            return artistQuery.page
        }
    }

    var firstEmptyPage: Int?
    
    init(filterForArtistGroup: ArtistGroup? = nil,
         filterForQuery: String? = nil,
         appContext: AppContext) {
        
        let artistQuery = ArtistQuery(page: 0,
                                  limit: 10,
                                  artistGroupId: filterForArtistGroup?.id,
                                  search: filterForQuery,
                                  include: Artist.includeParams)
        
        self.artistQuery = artistQuery
        super.init(appContext: appContext)
    }
    
    override func fetchListItems(forceReload: Bool = false) {
        if forceReload {
            self.artistQuery.page = 0
            self.firstEmptyPage = nil
        }
        if firstEmptyPage == artistQuery.page {
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
        
        _ = appContext.networkService.request(PrivateRouter.getArtists(query: artistQuery.makeURLParams())
        ) { [weak self] (result: UAResult<ArtistsContainer>) in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .failure(let error):
                    self?.errorMessage = error.userMessage
                case .success(let artistsContainer):
                    guard self != nil else { log.debug("no self!"); return }
                    if artistsContainer.artists.count == 0 {
                        self?.firstEmptyPage = self?.artistQuery.page
                        if !forceReload {
                            return
                        }
                    }
                    
                    if forceReload {
                        self!._listItems = artistsContainer.artists
                    } else {
                        self?._listItems.append(contentsOf: artistsContainer.artists)
                    }
                    let shouldReload = self!.artistQuery.page == 0
                    self!.didUpdateListItems?(self!.getNewIndexPaths(forAddedItems: artistsContainer.artists), [], shouldReload)
                    self!.artistQuery.page += 1
                }
            }
        }
    }
    
    public func setSearchQuery(_ query: String?) {
        self.artistQuery.search = query
    }
}
