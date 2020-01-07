//
//  PublicRouter.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-29.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

enum AuthRouter: EndpointConfiguration {
    
    case authenticate(email: String, password: String, username: String?, newUser: Bool)
    case resetPassword(email: String)
    
    var baseURL: URL {
        return URL(string: "\(Config.apiEndpoint)/auth")!
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .authenticate:
            return .post
        case .resetPassword:
            return .post
        }
    }
    
    var path: String {
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
    
    var task: HTTPTask {
        switch self {
        case .authenticate(let email, let password, let username, _):
            let body: Parameters = ["user": ["email": email, "password": password, "username": username],
                                    "refresh_token": "true"] as [String: Any]
            return .requestParameters(bodyParameters: body, urlParameters: nil)
        case .resetPassword(let email):
            return .requestParameters(bodyParameters: ["user": ["email": email]], urlParameters: nil)
        }
    }
    
    func getRequiredHeaders(keychainService: KeychainService) throws -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers["Content-type"] = "application/json"
        return headers
    }
}
