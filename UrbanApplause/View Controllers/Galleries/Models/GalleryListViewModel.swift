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

class GalleryListViewModel {
    typealias Snapshot = NSDiffableDataSourceSnapshot<GalleriesSection, GalleryCellViewModel>
    @Published private(set) var itemViewModels: [GalleryCellViewModel] = []
    let itemChanges = PassthroughSubject<CollectionDifference<GalleryCellViewModel>, Never>()

    var snapshot: AnyPublisher<Snapshot, Never> {
        collections
        .combineLatest(visits, applauded, posted)
        .map { collections, visits, applauded , posted in
            var snapshot = Snapshot()
            snapshot.appendSections([GalleriesSection.myCollections])
            snapshot.appendItems(collections.map { GalleryCellViewModel(galleryType: Gallery.custom($0), posts: $0.Posts ?? []) }, toSection: .myCollections)
            
            if self.includeGeneratedGalleries {
                snapshot.appendSections([GalleriesSection.other])
                
                snapshot.appendItems([GalleryCellViewModel(galleryType: .visits, posts: visits),
                                      GalleryCellViewModel(galleryType: .applause, posts: applauded),
                                      GalleryCellViewModel(galleryType: .posted, posts: posted)
                ], toSection: .other)
            }
            return snapshot
        }.eraseToAnyPublisher()
    }

    var includeGeneratedGalleries: Bool
    var userId: Int?
    var mainCoordinator: MainCoordinator
    
    var cancellables = Set<AnyCancellable>()
    private var collections = CurrentValueSubject<[Collection], Never>([])
    private var visits = CurrentValueSubject<[Post], Never>([])
    private var applauded = CurrentValueSubject<[Post], Never>([])
    private var posted = CurrentValueSubject<[Post], Never>([])

    private var collectionsLoading = CurrentValueSubject<Bool, Never>(false)
    private var visitsLoading = CurrentValueSubject<Bool, Never>(false)
    private var applaudedLoading = CurrentValueSubject<Bool, Never>(false)
    private var postedLoading = CurrentValueSubject<Bool, Never>(false)
    
    private var _errorMessage = CurrentValueSubject<String?, Never>(nil)

    public var errorMessage: AnyPublisher<String?, Never>!
    public var isLoading: AnyPublisher<Bool, Never>
    public var tableData: AnyPublisher<[GalleriesSection: [Gallery]], Never>!
    
    init(userId: Int?, includeGeneratedGalleries: Bool = true, mainCoordinator: MainCoordinator) {
        self.userId = userId
        self.includeGeneratedGalleries = includeGeneratedGalleries
        self.mainCoordinator = mainCoordinator
        
        self.errorMessage = _errorMessage.eraseToAnyPublisher()

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
    
    public func getData() {
        self.getCollections()
        if includeGeneratedGalleries {
            self.getVisits()
            self.getApplauded()
            self.getPosted()
        }
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
    private func getCollections() {
        guard let userId = self.userId else {
            self._errorMessage.value = "Must be logged in to view and create collections."
            return
        }
        guard !collectionsLoading.value else {
            return
        }
        _errorMessage.value = nil
        collectionsLoading.value = true
        let endpoint = PrivateRouter.getCollections(userId: userId, postId: nil)
        _ = mainCoordinator.networkService.request(endpoint) { [weak self] (result: UAResult<CollectionsContainer>) in
            DispatchQueue.main.async {
                self!.collectionsLoading.value = false
                log.debug("got collections")
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?._errorMessage.value = error.userMessage
                case .success(let collectionsContainer):
                    self?.collections.value = collectionsContainer.collections
                }
            }
        }
    }
    private func getVisits() {
        guard !visitsLoading.value else { return }
        visitsLoading.value = true
        let endpoint = PrivateRouter.getPosts(query: PostQuery(visitedBy: mainCoordinator.store.user.data?.id))
        _ = mainCoordinator.networkService.request(endpoint) { (result: UAResult<PostsContainer>) in
            DispatchQueue.main.async {
                self.visitsLoading.value = false
                switch result {
                case .failure(let error):
                    log.error(error)
                    self._errorMessage.value = error.userMessage
                case .success(let container):
                    self.visits.value = container.posts
                }
            }
        }
    }
    
    private func getApplauded() {
        guard !applaudedLoading.value else { return }
        applaudedLoading.value = true
        let endpoint = PrivateRouter.getPosts(query: PostQuery(applaudedBy: mainCoordinator.store.user.data?.id))
        _ = mainCoordinator.networkService.request(endpoint) { (result: UAResult<PostsContainer>) in
            DispatchQueue.main.async {
                self.applaudedLoading.value = false
                switch result {
                case .failure(let error):
                    log.error(error)
                    self._errorMessage.value = error.userMessage
                case .success(let container):
                    self.applauded.value = container.posts
                }
            }
        }
    }
    private func getPosted() {
        guard !postedLoading.value else { return }
        postedLoading.value = true
        let endpoint = PrivateRouter.getPosts(query: PostQuery(userId: mainCoordinator.store.user.data?.id))
        _ = mainCoordinator.networkService.request(endpoint) { (result: UAResult<PostsContainer>) in
            DispatchQueue.main.async {
                self.postedLoading.value = false
                switch result {
                case .failure(let error):
                    log.error(error)
                    self._errorMessage.value = error.userMessage
                case .success(let container):
                    self.posted.value = container.posts
                }
            }
        }
    }
}
