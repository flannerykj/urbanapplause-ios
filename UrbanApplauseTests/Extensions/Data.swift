//
//  Data.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

extension Data {
    func json(deletingKeyPaths keyPaths: String...) throws -> Data {
        let decoded = try JSONSerialization.jsonObject(with: self, options: .mutableContainers) as AnyObject
        
        for keyPath in keyPaths {
            decoded.setValue(nil, forKeyPath: keyPath)
        }
        
        return try JSONSerialization.data(withJSONObject: decoded)
    }
}
