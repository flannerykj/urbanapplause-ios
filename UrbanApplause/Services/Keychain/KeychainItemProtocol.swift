//
//  KeychainService.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-10.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

protocol KeychainItemProtocol {
    func readItem<T: Codable>() throws -> T
    func saveItem<T>(_ item: T) throws where T: Codable
}
