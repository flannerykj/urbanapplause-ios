//
//  TourMapViewModel.swift
//  UrbanApplause
//
//  Created by Flann on 2020-12-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import Shared
import MapKit

class WaypointViewModel: NSObject {
    let post: Post
    private(set) var distance: CLLocationDistance?
    
    init(post: Post, distance: CLLocationDistance?) {
        self.post = post
        self.distance = distance
    }
    
    func updatedStartingLocation(_ clLocation: CLLocation) {
        guard let postLocation = post.Location?.clLocation else { return }
        self.distance = postLocation.distance(from: clLocation)
    }
}


protocol TourMapDataStreaming {
    var startingPoint: CLLocation? { get }
    var collection: Collection { get }
    var annotationsStream: AnyPublisher<[WaypointViewModel], Never> { get }
    var errorMessageStream: AnyPublisher<String?, Never> { get }
    var isLoadingStream: AnyPublisher<Bool, Never> { get }
    var selectedAnnotationIndex: AnyPublisher<Int?, Never> { get }
    
    func fetchPosts()
    func setSelectedPostIndex(_ index: Int?)
    func updateStartingPoint(_ clLocation: CLLocation)
}

class TourMapDataStream: TourMapDataStreaming {
    private(set) var startingPoint: CLLocation?
    private let appContext: AppContext
    
    init(appContext: AppContext, collection: Collection) {
        self.appContext = appContext
        self.collection = collection
    }
    // MARK: - TourMapDataStreaming
    let collection: Collection

    var annotationsStream: AnyPublisher<[WaypointViewModel], Never> {
        mutableAnnotationsStream.eraseToAnyPublisher()
    }
    var errorMessageStream: AnyPublisher<String?, Never> {
        mutableErrorMessageStream.eraseToAnyPublisher()
    }
    var isLoadingStream: AnyPublisher<Bool, Never> {
        mutableIsLoadingStream.eraseToAnyPublisher()
    }
    
    var selectedAnnotationIndex: AnyPublisher<Int?, Never> {
        selectedIndexSubject.eraseToAnyPublisher()
    }
    func fetchPosts() {
        let query = PostQuery(page: 0,
                            limit: 100,
                            userId: nil,
                            applaudedBy: nil,
                            artistId: nil,
                            search: nil,
                            collectionId: collection.id,
                            proximity: nil,
                            bounds: nil,
                            include: ["post_images", "artists", "location", "user"])
        _ = appContext.networkService.request(PrivateRouter.getPosts(query: query)
        ) { [weak self] (result: UAResult<PostsContainer>) in
            guard self != nil else { return }
            DispatchQueue.main.async {
                self!.mutableIsLoadingStream.send(false)
                switch result {
                case .failure(let error):
                    self?.mutableErrorMessageStream.send(error.localizedDescription)
                case .success(let container):
                    self?.posts = container.posts
                    let waypoints = self?.getSortedWaypointViewModels(from: container.posts, startingPoint: self?.startingPoint) ?? []
                    self?.mutableAnnotationsStream.send(waypoints)
                }
            }
        }
    }
    
    func updateStartingPoint(_ clLocation: CLLocation) {
        startingPoint = clLocation
        let waypoints = getSortedWaypointViewModels(from: self.posts, startingPoint: clLocation)
        mutableAnnotationsStream.send(waypoints)
    }
    
    func setSelectedPostIndex(_ index: Int?) {
        selectedIndexSubject.send(index)
    }

    // MARK: - Private
    private var posts: [Post] = []
    
    private var mutableAnnotationsStream = CurrentValueSubject<[WaypointViewModel], Never>([])
    private var mutableErrorMessageStream = CurrentValueSubject<String?, Never>(nil)
    private var mutableIsLoadingStream = CurrentValueSubject<Bool, Never>(false)
    private var selectedIndexSubject = CurrentValueSubject<Int?, Never>(nil)
    
    private func getSortedWaypointViewModels(from posts: [Post], startingPoint: CLLocation?) -> [WaypointViewModel] {
        guard let startingPoint = startingPoint ?? posts.first?.Location?.clLocation else { return [] }
        let sorted = posts
            .map {
                WaypointViewModel(post: $0, distance: $0.Location?.clLocation.distance(from: startingPoint))
            }
            .sorted(by: { viewModelA, viewModelB in
            guard let distanceA = viewModelA.distance else { return false }
            guard let distanceB = viewModelB.distance else { return true }
            return distanceA < distanceB
        })
        return sorted
    }
}
