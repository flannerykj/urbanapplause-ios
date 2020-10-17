//
//  RemoteImageService.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-10-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public enum RemoteImageError: UAError {
    case invalidFilename
    case uploadError(String?)
    case downloadError(String?)
    case noData
    case custom(Error?)
    
    public var errorCode: UAErrorCode? { return nil }
    
    public var debugMessage: String {
        switch self {
        case .uploadError(let string):
            return string ?? "Unable to upload file"
        case .downloadError(let string):
            return string ?? "Unable to download file"
        case .custom(let error):
            return error?.localizedDescription ?? ""
        case .invalidFilename:
            return "Invalid image"
        case .noData:
            return "No data"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .uploadError(let string):
            return string ?? "Unable to upload file"
        case .downloadError(let string):
            return string ?? "Unable to download file"
        case .custom:
            return "Something went wrong"
        case .invalidFilename:
            return "Invalid image"
        case .noData:
            return "No data"
        }
    }
}

public protocol RemoteImageService {
    func downloadFile(filename: String,
                      updateProgress: @escaping (Double) -> Void,
                      completion: @escaping (Data?, RemoteImageError?) -> Void)
}
