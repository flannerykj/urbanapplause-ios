//
//  CollectionsService.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-16.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared
import Combine

protocol CollectionsAPIService: AnyObject {
    func getCollections(priority: NetworkServiceJobPriority) -> AnyPublisher<CollectionsContainer, Error>
    func getCollection(id: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<CollectionContainer, Error>
}

class CollectionsAPIServiceImpl: CollectionsAPIService {
    private let networkService: NetworkServiceV2
    
    init(networkService: NetworkServiceV2) {
        self.networkService = networkService
    }
    func getCollections(priority: NetworkServiceJobPriority = .primary) -> AnyPublisher<CollectionsContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .get, path: "collections", task: .request)
        return networkService.request(endpoint, priority: priority)
    }
    func getCollection(id: Int, priority: NetworkServiceJobPriority = .primary) -> AnyPublisher<CollectionContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .get, path: "collections/\(id)", task: .request)
        return networkService.request(endpoint, priority: priority)
    }
}

