//
//  ServerResponse.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct ServerResponse<T: Codable>: Codable {
    var statusCode: Int
    var data: T?
    var message: String?
}

struct ResultsResponseData<T: Codable>: Codable {
    var pageSize: Int
    var page: Int
    var total: Int
    var results: [T]
}

struct ServerErrorResponse: Decodable {
    var error: ServerErrorData
}

struct ServerErrorData: Decodable {
    var statusCode: Int
    var errorCode: Int
    var message: String
    var errors: [String]?
}

struct PostsContainer: Codable {
    var posts: [Post]
}

struct ImagesContainer: Codable {
    var images: [PostImage]
}

struct PostContainer: Codable {
    var post: Post
}

struct PostImageContainer: Codable {
    var image: PostImage?
}
