//
//  UAError.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-10.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum UAErrorCode: String, Decodable {
    case passwordStrength = "validation_password_strength"
    case invalidTFAToken = "2fa_invalid_token"
    case twoFactorRequired = "2fa_required" // navigate to 2fa form view & gather code before resubmitting login info
    
    case noTokenProvided = "no_token_provided"
    case tokenExpired = "token_expired"
    case tokenRevoked = "token_revoked"
    
    // means that the token was valid, but did not map to valid user in db.
    // probably user deleted or from diff environment (eg. prod vs dev db).
    case invalidToken = "invalid_token"
    
    var userMessage: String? {
        switch self {
        case .passwordStrength: return "Please select a stronger password."
        case .twoFactorRequired:
            return "Please provide your two-factor authentication code"
        case .invalidTFAToken:
            return "Invalid two-factor authentication code"
        case .tokenExpired, .tokenRevoked, .noTokenProvided:
            return "Your session has expired. Please log in again."
        case .invalidToken:
            return nil // should log out, no error message required. next log in will work. 
        }
    }
}
protocol UAError: Error {
    var errorCode: UAErrorCode? { get }
    var debugMessage: String { get }
    var userMessage: String { get }
}
