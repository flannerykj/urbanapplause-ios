//
//  KeychainMock.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
@testable import UrbanApplause

class KeychainServiceMock: KeychainService {
    var mockStorage: [String: Codable] = [:]
    
    init() {
        super.init(service: UUID().uuidString)
    }
    
    override func load<T>(itemAt userAccount: String,
                          isSecure: Bool = false) throws -> T where T: Decodable, T: Encodable {
        if let item = mockStorage[userAccount] as? T {
            return item
        } else {
            throw KeychainError.noData
        }
    }
    
    override func save<T>(item: T, to userAccount: String,
                          isSecure: Bool = false) throws where T: Decodable, T: Encodable {
        mockStorage[userAccount] = item
    }
    
    override func clear(itemAt userAccount: String) {
        mockStorage[userAccount] = nil
    }
}
