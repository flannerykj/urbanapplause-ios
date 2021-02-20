//
//  UserService.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-16.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared
import Combine

protocol UserAPIService: AnyObject {
    func getUser(id: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<UserContainer, Error>
}


class UserAPIServiceImpl: UserAPIService {
    private let networkService: NetworkServiceV2
    
    init(networkService: NetworkServiceV2) {
        self.networkService = networkService
    }
    
    func getUser(id: Int, priority: NetworkServiceJobPriority = .primary) -> AnyPublisher<UserContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .get, path: "user/\(id)", task: .request)
        return networkService.request(endpoint, priority: priority)
    }
}

