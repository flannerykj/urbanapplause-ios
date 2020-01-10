//
//  Errors.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

fileprivate let log = DHLogger.self

public enum UAErrorCode: String, Decodable {
    case passwordStrength = "validation_password_strength"
    case invalidTFAToken = "2fa_invalid_token"
    case twoFactorRequired = "2fa_required" // navigate to 2fa form view & gather code before resubmitting login info
    
    case noTokenProvided = "no_token_provided"
    case tokenExpired = "token_expired"
    case tokenRevoked = "token_revoked"
    
    // means that the token was valid, but did not map to valid user in db.
    // probably user deleted or from diff environment (eg. prod vs dev db).
    case invalidToken = "invalid_token"
    
    public var userMessage: String? {
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
public protocol UAError: Error {
    var errorCode: UAErrorCode? { get }
    var debugMessage: String { get }
    var userMessage: String { get }
}
public extension UAError {
    var debugMessage: String {
        return self.userMessage
    }
    
    var errorCode: UAErrorCode? {
        return nil
    }
}

public struct ServerErrorWrapper: Decodable {
    public var error: UAServerError
}

public enum ServerErrorName: String, Decodable {
    // backend custom error models
    case ValidationError, MissingParamsError, AccessDeniedError, BadRequestError, ServerError
}

public class UAServerError: Decodable, CustomStringConvertible {
    public var name: ServerErrorName?
    public var message: String?
    public var suggestions: [String]?
    public var code: UAErrorCode?
    public var fields: [String]?
    
    enum CodingKeys: CodingKey {
        case name, message, suggestions, code, fields
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self.name = try values.decodeIfPresent(ServerErrorName.self, forKey: .name)
        } catch {
            log.error(error)
            log.error("missing error name")
        }
        self.message = try? values.decodeIfPresent(String.self, forKey: .message)
        self.code = try? values.decodeIfPresent(UAErrorCode.self, forKey: .code)
        self.suggestions = try? values.decodeIfPresent([String].self, forKey: .suggestions)
        self.fields = try? values.decodeIfPresent([String].self, forKey: .fields)
    }
        
    public init(name: ServerErrorName, message: String? = nil, code: UAErrorCode? = nil) {
        self.name = name
        self.message = message
        self.code = code
    }

    public var description: String {
        return "Server Error: \(self.name?.rawValue ?? "") \(self.debugMessage)"
    }
    
}

extension UAServerError: UAError {
    public var errorCode: UAErrorCode? {
        return self.code
    }

    public var userMessage: String {
        return self.message ?? defaultUserMessage
    }
    public var debugMessage: String {
        return self.message ?? defaultDebugMessage
    }

    public var defaultUserMessage: String {
        switch self {
        default:
            return "An error occurred"
        }
    }

    public var defaultDebugMessage: String {
        switch self {
        default:
            return self.localizedDescription
        }
    }
    
}

public enum NetworkError: UAError {
    case fourOhFour, noResponse, dataNotFound, decodingError(error: Error), parameterEncodingFailed, invalidURL,
    requestTimeout, invalidCode(code: Int)

    public var errorCode: UAErrorCode? {
        switch self {
        default: return nil
        }
    }
    
    private var _message: String {
        switch self {
            
        case .fourOhFour:
            return "Network Error: 404"
        case .noResponse:
            return "Network Error: No response"
        case .dataNotFound:
            return "Network Error: Data not found"
        case .decodingError(let error):
            return "Network Error: Decoding failed. \(error)"
        case .parameterEncodingFailed:
            return "Network Error: Parameter encoding failed"
        case .invalidURL:
            return "Network Error: Invalid URL"
        case .requestTimeout:
            return "Network Error: Request Timeout"
        case .invalidCode(let code):
            return "Network Error: Invalid Response Code \(code)"
        }
    }
    public var debugMessage: String {
        switch self {
            
        case .fourOhFour:
            return "Network Error: 404"
        case .noResponse:
            return "Network Error: No response"
        case .dataNotFound:
            return "Network Error: Data not found"
        case .decodingError(let error):
            return "Network Error: Decoding failed. \(error)"
        case .parameterEncodingFailed:
            return "Network Error: Parameter encoding failed"
        case .invalidURL:
            return "Network Error: Invalid URL"
        case .requestTimeout:
            return "Network Error: Request Timeout"
        case .invalidCode(let code):
            return "Network Error: Invalid Response Code \(code)"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .requestTimeout:
            return "Your request timed out. Please check your network connection stability or try again later."
        case .noResponse:
            return "Your Internet connection appears to be offline."
        default: return _message
        }
    }
}
