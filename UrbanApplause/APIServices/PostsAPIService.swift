//
//  PostsService.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-16.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared
import Combine

protocol PostsAPIService: AnyObject {
    func getPost(id: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<PostContainer, Error>
    func getPosts(query: PostQuery, priority: NetworkServiceJobPriority) -> AnyPublisher<PostsContainer, Error>
    func getPostClusters(postedAfter: Date?, threshold: Double?, bounds: GeoBoundsFilter?, priority: NetworkServiceJobPriority) -> AnyPublisher<PostClustersContainer, Error>
    func createPost(values: [String: Any], priority: NetworkServiceJobPriority) -> AnyPublisher<PostContainer, Error>
    func deletePost(id: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<PostContainer, Error>
    func addOrRemoveClap(postId: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<ApplauseInteractionContainer, Error>
    func addOrRemoveVisit(postId: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<VisitInteractionContainer, Error>
}


class PostsAPIServiceImpl: PostsAPIService {

    private let networkService: NetworkServiceV2
    
    init(networkService: NetworkServiceV2) {
        self.networkService = networkService
    }
    
    func getPost(id: Int, priority: NetworkServiceJobPriority = .primary) -> AnyPublisher<PostContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .get, path: "post/\(id)", task: .request)
        return networkService.request(endpoint, priority: priority)
    }
    
    func getPosts(query: PostQuery, priority: NetworkServiceJobPriority = .primary) -> AnyPublisher<PostsContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .get, path: "posts", task: .requestParameters(bodyParameters: nil, urlParameters: query.makeURLParams()))
        return networkService.request(endpoint, priority: priority)
    }
    
    func getPostClusters(postedAfter: Date?, threshold: Double?, bounds: GeoBoundsFilter?, priority: NetworkServiceJobPriority) -> AnyPublisher<PostClustersContainer, Error> {
        var params = Parameters()
        if let bounds = bounds {
            params["lat1"] = String(bounds.neCoord.latitude)
            params["lng1"] = String(bounds.neCoord.longitude)
            params["lat2"] = String(bounds.swCoord.latitude)
            params["lng2"] = String(bounds.swCoord.longitude)
        }
        if let date = postedAfter {
            params["posted_after"] = String(date.timeIntervalSince1970)
        }
        if let threshold = threshold {
            params["threshold"] = String(threshold)
        }
        let endpoint = UAAPIEndpointConfig(httpMethod: .get, path: "posts/clusters", task: .requestParameters(bodyParameters: nil, urlParameters: params))
        return networkService.request(endpoint, priority: priority)
    }
    
    func createPost(values: [String: Any], priority: NetworkServiceJobPriority) -> AnyPublisher<PostContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .post, path: "posts", task: .requestParameters(bodyParameters: ["post": values], urlParameters: nil))
        return networkService.request(endpoint, priority: priority)
    }
    
    func deletePost(id: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<PostContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .delete, path: "posts/\(id)", task: .request)
        return networkService.request(endpoint, priority: priority)
    }
    
    func addOrRemoveClap(postId: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<ApplauseInteractionContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .post, path: "claps", task: .requestParameters(bodyParameters: ["clap": ["PostId": postId]], urlParameters: nil))
        return networkService.request(endpoint, priority: priority)
    }
    
    func addOrRemoveVisit(postId: Int, priority: NetworkServiceJobPriority) -> AnyPublisher<VisitInteractionContainer, Error> {
        let endpoint = UAAPIEndpointConfig(httpMethod: .post, path: "visits", task: .requestParameters(bodyParameters:  ["visit": ["PostId": postId]], urlParameters: nil))
        return networkService.request(endpoint, priority: priority)
    }
}

