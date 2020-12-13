//
//  CollectionListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import UIKit
import Shared


struct GalleryQuery {
    var postId: Int?
    var userId: Int?
    var isPublic: Bool?
    var searchQuery: String?
}

class GalleryListViewModel {
    let isEditable: Bool
    typealias Snapshot = NSDiffableDataSourceSnapshot<GalleriesSection, GalleryCellViewModel>
    private(set) var noResultsMessage = CurrentValueSubject<String, Never>("")
    private(set) var errorMessage = CurrentValueSubject<String, Never>("")

    @Published private(set) var itemViewModels: [GalleryCellViewModel] = []
    let itemChanges = PassthroughSubject<CollectionDifference<GalleryCellViewModel>, Never>()
    
    var snapshot: AnyPublisher<Snapshot, Never> {
        collections
        .combineLatest(visits, applauded, posted)
        .map { collections, visits, applauded , posted in
            var snapshot = Snapshot()
            snapshot.appendSections([GalleriesSection.collections])
            snapshot.appendItems(collections.map { GalleryCellViewModel(galleryType: Gallery.custom($0), posts: $0.Posts ?? []) }, toSection: .collections)
            
            return snapshot
        }.eraseToAnyPublisher()
    }

    var userId: Int?
    var appContext: AppContext
    
    var cancellables = Set<AnyCancellable>()
    private var collections = CurrentValueSubject<[Collection], Never>([])
    private var visits = CurrentValueSubject<[Post], Never>([])
    private var applauded = CurrentValueSubject<[Post], Never>([])
    private var posted = CurrentValueSubject<[Post], Never>([])

    private var collectionsLoading = CurrentValueSubject<Bool, Never>(false)
    private var visitsLoading = CurrentValueSubject<Bool, Never>(false)
    private var applaudedLoading = CurrentValueSubject<Bool, Never>(false)
    private var postedLoading = CurrentValueSubject<Bool, Never>(false)
    
    public var isLoading: AnyPublisher<Bool, Never>
    public var tableData: AnyPublisher<[GalleriesSection: [Gallery]], Never>!
    
    private var filterByQuery: GalleryQuery

    init(userId: Int?, appContext: AppContext, initialQuery: GalleryQuery, isEditable: Bool = false) {
        self.userId = userId
        self.appContext = appContext
        self.filterByQuery = initialQuery
        self.isEditable = isEditable
        
        self.isLoading = collectionsLoading
            .combineLatest(applaudedLoading, visitsLoading, postedLoading)
            .map { collectionsLoading, applaudedLoading, visitsLoading, postedLoading in
                return collectionsLoading || visitsLoading || applaudedLoading || postedLoading
        }.eraseToAnyPublisher()
        
        $itemViewModels.zip(itemChanges) { existingModels, changes in
            var newModels = existingModels
            for change in changes {
                switch change {
                case .remove(let offset, _, _):
                    newModels.remove(at: offset)
                case .insert(let offset, let cellModel, _):
                    let model = cellModel
                    // can apply transformations here....
                    newModels.insert(model, at: offset)
                }
            }
            return newModels
        }.assign(to: \.itemViewModels, on: self).store(in: &cancellables)
    }
    
    public func getData(query: GalleryQuery) {
        self.filterByQuery = query
        self.getCollections()
    }
    
    public func refreshData() {
        self.getCollections()
    }
    
    public func addCollection(_ collection: Collection) {
        let updatedCollections = self.collections.value + [collection]
        self.collections.value = updatedCollections
    }
    public func removeCollection(_ collection: Collection) {
        var updatedCollections = self.collections.value
        updatedCollections.removeAll(where: { $0.id == collection.id })
        self.collections.value = updatedCollections
    }
    
    public func updateCollection(_ collection: Collection) {
        let updated: [Collection] = self.collections.value.map { (currCollection: Collection) in
            if currCollection.id == collection.id { return currCollection }
            return currCollection
        }
        self.collections.value = updated
    }
    
    public func deleteCollection(atIndexPath indexPath: IndexPath) {
        let collection = self.collections.value[indexPath.row]
       
        _ = appContext.networkService.request(PrivateRouter.deleteCollection(id: collection.id), completion: { (result: UAResult<Collection>) in
            
        })
        removeCollection(collection)
    }
    private func getCollections() {
        guard !collectionsLoading.value else {
            return
        }
        noResultsMessage.value = ""
        errorMessage.value = ""
        collectionsLoading.value = true
        let endpoint = PrivateRouter.getCollections(userId: filterByQuery.userId,
                                                    postId: filterByQuery.postId,
                                                    query: filterByQuery.searchQuery,
                                                    isPublic: filterByQuery.isPublic)
        _ = appContext.networkService.request(endpoint) { [weak self] (result: UAResult<CollectionsContainer>) in
            DispatchQueue.main.async {
                self!.collectionsLoading.value = false
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.errorMessage.value = error.userMessage
                    self?.collections.value = []
                case .success(let collectionsContainer):
                    if collectionsContainer.collections.count == 0 {
                        self?.noResultsMessage.value = "No results"
                    }
                    self?.collections.value = collectionsContainer.collections
                }
            }
        }
    }
    
    
}
