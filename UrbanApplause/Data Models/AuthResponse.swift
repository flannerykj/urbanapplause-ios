//
//  AuthUser.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-18.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct AuthResponse: Codable {
    var access_token: String
    var refresh_token: String?
    var user: User?
}
