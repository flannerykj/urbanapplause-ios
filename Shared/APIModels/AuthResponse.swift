//
//  AuthResponse.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct AuthResponse: Codable {
    public var access_token: String
    public var refresh_token: String?
    public var user: User?
}
