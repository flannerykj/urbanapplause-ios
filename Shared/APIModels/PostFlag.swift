//
//  PostFlag.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct PostFlag: Codable {
    public var PostId: Int
    public var UserId: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var Post: Post?
    public var User: User?
    public var status: PostFlagStatus
    public var user_reason: PostFlagReason
}
public struct CommentFlag: Codable {
    public var CommentId: Int
    public var UserId: Int
    public var createdAt: Date
    public var updatedAt: Date
    public var Comment: Comment?
    public var User: User?
    public var status: PostFlagStatus
    public var user_reason: PostFlagReason
}

public enum PostFlagStatus: String, Codable {
    case PendingReview, InReview, Dismissed, Addressed
}
public enum PostFlagReason: String, CaseIterable, Codable {
    case /* notInterested */ suspiciousOrSpam, sensitivePhoto, abusiveOrHarmful, selfHarmOrSuicide
    
    public var title: String {
        switch self {
        /* case .notInterested:
            return "I'm not interested in this post" */
        case .suspiciousOrSpam:
            return "It's suspicious or spam"
        case .sensitivePhoto:
            return "It displays a sensitive photo"
        case .abusiveOrHarmful:
            return "It's abusive or harmful"
        case .selfHarmOrSuicide:
            return "It expresses intentions of self-harm or suicide"
        }
    }
}
public struct PostFlagContainer: Codable {
    public var post_flag: PostFlag
}
public struct CommentFlagContainer: Codable {
    public var comment_flag: CommentFlag
}
