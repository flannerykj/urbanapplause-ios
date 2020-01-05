//
//  RouterConfiguration.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

protocol EndpointConfiguration {
    var baseURL: URL { get }
    var httpMethod: HTTPMethod { get }
    var path: String { get }
    var task: HTTPTask { get }
    func getRequiredHeaders(keychainService: KeychainService) throws -> HTTPHeaders
}
