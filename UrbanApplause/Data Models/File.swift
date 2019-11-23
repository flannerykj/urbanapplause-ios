//
//  File.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

protocol File: Codable {
    var storage_location: String { get set }
    var filename: String { get set }
    var mimetype: String? { get set }
}
