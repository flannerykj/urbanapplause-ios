//
//  Visit.swift
//  UrbanVisit
//
//  Created by Flannery Jefferson on 2019-12-02.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct Visit: Codable {
    var id: Int
    var UserId: Int
    var PostId: Int
    
    var Post: Post?
    var User: User?
}

struct VisitInteractionContainer: Codable {
    var visit: Visit
}
