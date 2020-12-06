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

protocol TourMapDataStreaming {
    var collection: Collection { get }
    var annotationsStream: AnyPublisher<[Post], Never> { get }
    var errorMessageStream: AnyPublisher<String?, Never> { get }
    var isLoadingStream: AnyPublisher<Bool, Never> { get }
    var selectedAnnotationIndex: AnyPublisher<Int?, Never> { get }
    
    func fetchPosts()
    func setSelectedPostIndex(_ index: Int?)
    
    
}

class TourMapDataStream: TourMapDataStreaming {
    private let appContext: AppContext
    
    init(appContext: AppContext, collection: Collection) {
        self.appContext = appContext
        self.collection = collection
    }
    // MARK: - TourMapDataStreaming
    let collection: Collection

    var annotationsStream: AnyPublisher<[Post], Never> {
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
                    self!.mutableAnnotationsStream.send(container.posts)
                }
            }
        }
    }
    func setSelectedPostIndex(_ index: Int?) {
        selectedIndexSubject.send(index)
    }

    // MARK: - Private
    private var mutableAnnotationsStream = CurrentValueSubject<[Post], Never>([])
    private var mutableErrorMessageStream = CurrentValueSubject<String?, Never>(nil)
    private var mutableIsLoadingStream = CurrentValueSubject<Bool, Never>(false)
    private var selectedIndexSubject = CurrentValueSubject<Int?, Never>(nil)

    
}
