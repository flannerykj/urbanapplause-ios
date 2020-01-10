//
//  File.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public protocol File: Codable {
    var storage_location: String { get set }
    var filename: String { get set }
    var mimetype: String? { get set }
}
