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
    case sendPasswordResetEmail(email: String)
    case updatePassword(newPassword: String, email: String, resetToken: String)
    
    public var baseURL: URL {
        return URL(string: "\(Config.apiEndpoint)/auth")!
    }
    
    public var httpMethod: HTTPMethod {
        switch self {
        case .authenticate:
            return .post
        case .sendPasswordResetEmail:
            return .post
        case .updatePassword:
            return .put
        }
    }
    
    public var path: String {
        switch self {
        case .authenticate(_, _, _, let newUser):
            if newUser {
                return "register"
            }
            return "login"
        case .sendPasswordResetEmail:
            return "reset-password"
        case .updatePassword(_, _, let resetToken):
            return "update-password/\(resetToken)"
        }
    }
    
    public var task: HTTPTask {
        switch self {
        case .authenticate(let email, let password, let username, _):
            let body: Parameters = ["user": ["email": email, "password": password, "username": username],
                                    "refresh_token": "true"] as [String: Any]
            return .requestParameters(bodyParameters: body, urlParameters: nil)
        case .sendPasswordResetEmail(let email):
            return .requestParameters(bodyParameters: ["user": ["email": email]], urlParameters: nil)
        case .updatePassword(let newPassword, let email, _):
            return .requestParameters(bodyParameters: ["user": ["password": newPassword, "email": email]], urlParameters: nil)
        }
    }
}
