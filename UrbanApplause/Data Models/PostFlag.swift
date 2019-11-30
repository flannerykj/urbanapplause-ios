//
//  PostFlag.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-31.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct PostFlag: Codable {
    var PostId: Int
    var UserId: Int
    var createdAt: Date
    var updatedAt: Date
    var Post: Post?
    var User: User?
    var status: PostFlagStatus
    var user_reason: PostFlagReason
}
struct CommentFlag: Codable {
    var CommentId: Int
    var UserId: Int
    var createdAt: Date
    var updatedAt: Date
    var Comment: Comment?
    var User: User?
    var status: PostFlagStatus
    var user_reason: PostFlagReason
}

enum PostFlagStatus: String, Codable {
    case PendingReview, InReview, Dismissed, Addressed
}
enum PostFlagReason: String, CaseIterable, Codable {
    case /* notInterested */ suspiciousOrSpam, sensitivePhoto, abusiveOrHarmful, selfHarmOrSuicide
    
    var title: String {
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
struct PostFlagContainer: Codable {
    var post_flag: PostFlag
}
struct CommentFlagContainer: Codable {
    var comment_flag: CommentFlag
}
