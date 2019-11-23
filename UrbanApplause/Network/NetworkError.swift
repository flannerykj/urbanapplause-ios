//
//  NetworkError.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-12.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum NetworkError: UAError {
    case fourOhFour, noResponse, dataNotFound, decodingError(error: Error), parameterEncodingFailed, invalidURL,
    requestTimeout, invalidCode(code: Int)

    var errorCode: UAErrorCode? {
        switch self {
        default: return nil
        }
    }
    
    var debugMessage: String {
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
    
    var userMessage: String {
        switch self {
        case .requestTimeout:
            return "Your request timed out. Please check your network connection stability or try again later."
        default: return "Something went wrong. We're working on fixing it."
        }
    }
}
