//
//  SearchViewModel.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-13.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared
import Combine

protocol SearchInteractable: AnyObject {
    func fetchContent(forQuery query: String?)
}

class SearchInteractor: NSObject, SearchInteractable {
    private var cancellables = Set<AnyCancellable>()
    private var searchQuery = CurrentValueSubject<String?, Never>(nil)
    
    private weak var viewControllable: SearchViewControllable?
    private let appContext: AppContext
    
    init(viewControllable: SearchViewControllable, appContext: AppContext) {
        self.viewControllable = viewControllable
        self.appContext = appContext
        
        super.init()
        
        subscribeToSearchQuery()
    }
    
    func fetchContent(forQuery query: String?) {
        searchQuery.value = query
    }
    
    // MARK: - Private
    
    private func subscribeToSearchQuery(include types: [String] = ["posts", "artists", "locations", "collections", "artist_groups", "users"]) {
        searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { query in
                guard let q = query else { return }
                _ = self.appContext.networkService.request(PrivateRouter.search(query: q, includeTypes: types), completion: { (result: UAResult<SearchResultsResponse>) in
                    switch result {
                    case .success(let response):
                        let results = self.makeSearchResults(from: response.results)
                        self.viewControllable?.updateSearchResults(results)
                    case .failure(let error):
                        log.error(error)
                    }
                })
            })
            .store(in: &cancellables)
        
    }
    
    private func makeSearchResults(from results: SearchResults) -> [SearchResultSection] {
        
        var sections: [SearchResultSection] = []
        

        if let groups = results.artist_groups, groups.count > 0 {
            sections.append(.groups(groups))
        }

        if let locations = results.locations, locations.count > 0 {
            sections.append(.locations(locations))
        }
        
        if let collections = results.collections, collections.count > 0 {
            sections.append(.collections(collections))
        }
        
        if let users = results.users, users.count > 0 {
            sections.append(.users(users))
        }
        
        
        if let artists = results.artists, artists.count > 0 {
            sections.append(.artists(artists))
        }
        
        if let posts = results.posts, posts.count > 0 {
            sections.append(.posts(posts))
        }
        
        return sections
    }
}
