//
//  SearchResultsInteractor.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-14.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import Shared

protocol SearchResultsViewControllable: AnyObject {
    var listener: SearchResultsViewControllerListener? { get set }
    func updateSearchResults(_ results: [SearchResultSection])
}
protocol SearchResultsListener: AnyObject {
    func didSelectItem(inSection section: SearchResultSection, at row: Int)
}

class SearchResultsInteractor: NSObject, SearchResultsViewControllerListener {
    weak var listener: SearchResultsListener?
    private let appContext: AppContext
    private var cancellables = Set<AnyCancellable>()
    private var searchQuery = CurrentValueSubject<(String?, [SearchResultSection]), Never>((nil, []))
    private weak var viewControllable: SearchResultsViewControllable?
    private var results: [SearchResultSection] = []
    
    init(appContext: AppContext, viewControllable: SearchResultsViewControllable) {
        self.appContext = appContext
        self.viewControllable = viewControllable
        super.init()
        viewControllable.listener = self
        
        subscribeToSearchQuery()
    }
    
    // MARK: - SearchV2ViewControllerListener
    func didUpdateSearchQuery(_ query: String?, scopes: [SearchResultSection]) {
        searchQuery.value = (query, scopes)
    }
    
    func didSelectItemAt(indexPath: IndexPath) {
        let section = results[indexPath.section]
        listener?.didSelectItem(inSection: section, at: indexPath.row)
    }
    
    // MARK: - Private
    
    private func subscribeToSearchQuery() {
        searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .sink(receiveValue: { query, scopes in
                guard let q = query else { return }
                let types = scopes.map { $0.identifier }
                _ = self.appContext.networkService.request(PrivateRouter.search(query: q, includeTypes: types), completion: { (result: UAResult<SearchResultsResponse>) in
                    switch result {
                    case .success(let response):
                        self.results = self.makeSearchResults(from: response.results)
                        self.viewControllable?.updateSearchResults(self.results)
                    case .failure(let error):
                        log.error(error)
                    }
                })

            })
            .store(in: &cancellables)
    }
    
    private func searchAll(query: String) {
        let types = ["artists", "locations", "collections", "artist_groups", "users"]
        _ = self.appContext.networkService.request(PrivateRouter.search(query: query, includeTypes: types), completion: { (result: UAResult<SearchResultsResponse>) in
            switch result {
            case .success(let response):
                let results = self.makeSearchResults(from: response.results)
                self.viewControllable?.updateSearchResults(results)
            case .failure(let error):
                log.error(error)
            }
        })
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
