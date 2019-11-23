//
//  PostInteraction.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct Applause: Codable {
    var id: Int
    var UserId: Int
    var PostId: Int
    
    var Post: Post?
    var User: User?
}

struct ApplauseInteractionContainer: Codable {
    var applause: Applause
}
