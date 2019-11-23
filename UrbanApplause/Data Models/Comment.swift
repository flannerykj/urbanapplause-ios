//
//  Comment.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

class Comment: Codable {
    var id: Int
    var content: String?
    var PostId: Int
    var UserId: Int
    var createdAt: Date
    var updatedAt: Date
    var Post: Post?
    var User: User?
}

struct CommentsContainer: Codable {
    var comments: [Comment]
}
struct CommentContainer: Codable {
    var comment: Comment
}
