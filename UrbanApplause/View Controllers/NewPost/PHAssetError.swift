//
//  PHAssetError.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum PHAssetError: UAError {
    case failedToGetData(String?)
    
    var errorCode: UAErrorCode? { return nil }
    
    var userMessage: String {
        return "Unable to retrieve image data."
    }
    var debugMessage: String {
        switch self {
        case .failedToGetData(let message):
            return "PHAsset - FailedToGetData: \(message ?? "")"
        }
    }
}
