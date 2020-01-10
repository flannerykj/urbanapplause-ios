//
//  EndpointConfiguration.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public protocol EndpointConfiguration {
    var baseURL: URL { get }
    var httpMethod: HTTPMethod { get }
    var path: String { get }
    var task: HTTPTask { get }
    // func getRequiredHeaders(keychainService: KeychainService) throws -> HTTPHeaders
}
