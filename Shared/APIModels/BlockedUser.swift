//
//  BlockedUser.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct BlockedUser: Codable {
    public var BlockedUserId: Int
    public var BlockingUserId: Int
    public var createdAt: Date?
    public var updatedAt: Date?
}

public struct BlockedUserContainer: Codable {
    public var blocked_user: BlockedUser
}
