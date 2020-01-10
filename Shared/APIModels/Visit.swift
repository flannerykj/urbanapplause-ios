//
//  Visit.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct Visit: Codable {
    public var id: Int
    public var UserId: Int
    public var PostId: Int
    
    public var Post: Post?
    public var User: User?
}

public struct VisitInteractionContainer: Codable {
    public var deleted: Bool
    public var visit: Visit
}
