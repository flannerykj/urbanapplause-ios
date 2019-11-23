//
//  User.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct User: Codable {
    var id: Int
    var username: String?
    var email: String?
    var dob: Date?
    var first_name: String?
    var last_name: String?
    var Collections: [Collection]?
    var bio: String?
    var createdAt: Date?
    var updatedAt: Date?
}

struct UserContainer: Codable {
    var user: User
}
