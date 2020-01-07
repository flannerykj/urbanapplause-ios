//
//  NetworkError.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-10.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

struct ServerErrorWrapper: Decodable {
    var error: UAServerError
}

enum ServerErrorName: String, Decodable {
    // backend custom error models
    case ValidationError, MissingParamsError, AccessDeniedError, BadRequestError, ServerError
}

class UAServerError: Decodable, CustomStringConvertible {
    var name: ServerErrorName?
    var message: String?
    var suggestions: [String]?
    var code: UAErrorCode?
    var fields: [String]?
    
    enum CodingKeys: CodingKey {
        case name, message, suggestions, code, fields
    }
    
    required init(from decoder: Decoder) throws {
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
        
    init(name: ServerErrorName, message: String? = nil, code: UAErrorCode? = nil) {
        self.name = name
        self.message = message
        self.code = code
    }

    var description: String {
        return "Server Error: \(self.name?.rawValue ?? "") \(self.debugMessage)"
    }
    
}

extension UAServerError: UAError {
    var errorCode: UAErrorCode? {
        return self.code
    }

    var userMessage: String {
        return self.message ?? defaultUserMessage
    }
    var debugMessage: String {
        return self.message ?? defaultDebugMessage
    }

    var defaultUserMessage: String {
        switch self {
        default:
            return "An error occurred"
        }
    }

    var defaultDebugMessage: String {
        switch self {
        default:
            return self.localizedDescription
        }
    }
    
}
