//
//  BlockedUser.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct BlockedUser: Codable {
    var BlockedUserId: Int
    var BlockingUserId: Int
    var createdAt: Date?
    var updatedAt: Date?
}

struct BlockedUserContainer: Codable {
    var blocked_user: BlockedUser
}
