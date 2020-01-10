//
//  Comment.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public class Comment: Codable {
    public var id: Int
    public var content: String?
    public var PostId: Int
    public var UserId: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var Post: Post?
    public var User: User?
}

public struct CommentsContainer: Codable {
    public var comments: [Comment]
}
public struct CommentContainer: Codable {
    public var comment: Comment
}
