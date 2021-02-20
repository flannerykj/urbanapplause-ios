//
//  AuthService.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-17.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared
import Combine

protocol AuthAPIService: AnyObject {
    func login(email: String, password: String) -> AnyPublisher<AuthResponse?, Error>
    func register(email: String, username: String, password: String) -> AnyPublisher<AuthResponse?, Error>
    func sendPasswordResetEmail(email: String) -> AnyPublisher<MessageContainer, Error>
    func updatePassword(newPassword: String, email: String, resetToken: String) -> AnyPublisher<AuthResponse, Error>
}


class AuthAPIServiceImpl: AuthAPIService {
    private let networkService: NetworkServiceV2
    
    init(networkService: NetworkServiceV2) {
        self.networkService = networkService
    }
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse?, Error> {
        let body: Parameters = ["user": ["email": email, "password": password],
                                "refresh_token": "true"] as [String: Any]
        let endpoint = UAAPIEndpointConfig(httpMethod: .post, path: "login", task: .requestParameters(bodyParameters: body, urlParameters: nil))
        return networkService.request(endpoint, priority: .primary)
    }
    func register(email: String, username: String, password: String) -> AnyPublisher<AuthResponse?, Error> {
        let body: Parameters = ["user": ["email": email, "password": password, "username": username],
                                "refresh_token": "true"] as [String: Any]
        
        let endpoint = UAAPIEndpointConfig(httpMethod: .post, path: "login", task: .requestParameters(bodyParameters: body, urlParameters: nil))
        return networkService.request(endpoint, priority: .primary)
    }
    
    func sendPasswordResetEmail(email: String) -> AnyPublisher<MessageContainer, Error> {
        let body = ["user": ["email": email]]
        let endpoint = UAAPIEndpointConfig(httpMethod: .post, path: "reset-password", task: .requestParameters(bodyParameters: body, urlParameters: nil))
        return networkService.request(endpoint, priority: .primary)
    }
    
    func updatePassword(newPassword: String, email: String, resetToken: String) -> AnyPublisher<AuthResponse, Error> {
        let body = ["user": ["password": newPassword, "email": email]]
        let endpoint = UAAPIEndpointConfig(httpMethod: .put, path: "update-password/\(resetToken)", task: .requestParameters(bodyParameters: body, urlParameters: nil))
        return networkService.request(endpoint, priority: .primary)
    }
}

