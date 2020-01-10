//
//  User.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct User: Codable {
    public var id: Int
    public var username: String?
    public var email: String?
    public var dob: Date?
    public var first_name: String?
    public var last_name: String?
    public var Collections: [Collection]?
    public var bio: String?
    public var createdAt: Date?
    public var updatedAt: Date?
}

public struct UserContainer: Codable {
    public var user: User
}
