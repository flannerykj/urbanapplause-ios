//
//  AuthRouter.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

fileprivate let log = DHLogger.self

public enum AuthRouter: EndpointConfiguration {
    
    case authenticate(email: String, password: String, username: String?, newUser: Bool)
    case resetPassword(email: String)
    
    public var baseURL: URL {
        return URL(string: "\(Config.apiEndpoint)/auth")!
    }
    
    public var httpMethod: HTTPMethod {
        switch self {
        case .authenticate:
            return .post
        case .resetPassword:
            return .post
        }
    }
    
    public var path: String {
        switch self {
        case .authenticate(_, _, _, let newUser):
            if newUser {
                return "register"
            }
            return "login"
        case .resetPassword:
            return "reset-password"
        }
    }
    
    public var task: HTTPTask {
        switch self {
        case .authenticate(let email, let password, let username, _):
            let body: Parameters = ["user": ["email": email, "password": password, "username": username],
                                    "refresh_token": "true"] as [String: Any]
            return .requestParameters(bodyParameters: body, urlParameters: nil)
        case .resetPassword(let email):
            return .requestParameters(bodyParameters: ["user": ["email": email]], urlParameters: nil)
        }
    }
    
//    func getRequiredHeaders(keychainService: KeychainService) throws -> HTTPHeaders {
//        var headers = HTTPHeaders()
//        headers["Content-type"] = "application/json"
//        return headers
//    }
}
