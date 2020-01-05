//
//  FileError.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

enum FileError: UAError {
    case badData
    
    var errorCode: UAErrorCode? {
        return nil
    }
    
    var debugMessage: String {
        return "Unable to get file"
    }
    
    var userMessage: String {
        return "Unable to get file"
    }
    
}
