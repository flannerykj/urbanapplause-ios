//
//  CollectionPost.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct CollectionPost: Codable {
    public var id: Int
    public var UserId: Int
    public var CollectionId: Int
    public var annotation: String
}
