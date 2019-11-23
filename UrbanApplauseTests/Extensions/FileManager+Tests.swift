//
//  FileManager+Tests.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

extension FileManager {
    
    // MARK: - Common Directories
    static var temporaryDirectoryPath: String {
        return NSTemporaryDirectory()
    }
    
    static var temporaryDirectoryURL: URL {
        return URL(fileURLWithPath: FileManager.temporaryDirectoryPath, isDirectory: true)
    }
    
    // MARK: - File System Modification
    @discardableResult
    static func createDirectory(atPath path: String) -> Bool {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    static func createDirectory(at url: URL) -> Bool {
        return createDirectory(atPath: url.path)
    }
    
    @discardableResult
    static func removeItem(atPath path: String) -> Bool {
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }
    
    @discardableResult
    static func removeItem(at url: URL) -> Bool {
        return removeItem(atPath: url.path)
    }
    
    @discardableResult
    static func removeAllItemsInsideDirectory(atPath path: String) -> Bool {
        let enumerator = FileManager.default.enumerator(atPath: path)
        var result = true
        
        while let fileName = enumerator?.nextObject() as? String {
            let success = removeItem(atPath: path + "/\(fileName)")
            if !success { result = false }
        }
        
        return result
    }
    
    @discardableResult
    static func removeAllItemsInsideDirectory(at url: URL) -> Bool {
        return removeAllItemsInsideDirectory(atPath: url.path)
    }
}
