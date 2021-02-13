//
//  AuthUser.swift
//  Shared
//
//  Created by Flann on 2021-02-09.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct AuthUser: Codable {
    
    //
    //💜 VERBOSE NetworkServiceProtocol handleResponse:53 -- ["json: ", ["user": {
    //    blocked = 0;
    //    "created_at" = "2021-02-09T09:45:42.887Z";
    //    email = "ellameno123+tester@gmail.com";
    //    "email_verified" = 0;
    //    id = "772f2b05-0139-43af-8f3a-764ff6e070e3";
    //    "last_ip" = "174.119.232.19";
    //    role = contributor;
    //    "tfa_enabled" = 0;
    //}]]
}


public struct AuthUserResponse: Codable {
    var user: AuthUser
}
