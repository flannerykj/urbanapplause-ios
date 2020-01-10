//
//  FileError.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public enum FileError: UAError {
    case badData
    
    public var errorCode: UAErrorCode? {
        return nil
    }
    
    public var debugMessage: String {
        return "Unable to get file"
    }
    
    public var userMessage: String {
        return "Unable to get file"
    }
    
}
