//
//  Errors.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

enum AuthError: UAError {
    case notAuthenicated
    
    var userMessage: String {
        return "You are not currently logged into Urban Applause. Log in and try again."
    }
    var errorCode: UAErrorCode? {
        return nil
    }
    var debugMessage: String {
        return self.userMessage
    }
}

enum AttachmentError: UAError {
    case noneProvided, unableToLoad(Error?), invalidData(Error?)
    
    var userMessage: String {
        switch self {
        case .noneProvided:
            return "No attachemts provided"
        case .unableToLoad(let error):
            return "Unable to load attachment"
        case .invalidData(let error):
            return "Invalid attachment data"
        }
    }
    var errorCode: UAErrorCode? {
        return nil
    }
    var debugMessage: String {
        return self.userMessage
    }
}
