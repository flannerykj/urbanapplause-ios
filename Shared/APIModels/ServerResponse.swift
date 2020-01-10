//
//  ServerResponse.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct ServerResponse<T: Codable>: Codable {
    public var statusCode: Int
    public var data: T?
    public var message: String?
}

public struct ResultsResponseData<T: Codable>: Codable {
    public var pageSize: Int
    public var page: Int
    public var total: Int
    public var results: [T]
}

public struct ServerErrorResponse: Decodable {
    public var error: ServerErrorData
}

public struct ServerErrorData: Decodable {
    public var statusCode: Int
    public var errorCode: Int
    public var message: String
    public var errors: [String]?
}

public struct PostsContainer: Codable {
    public var posts: [Post]
}

public struct ImagesContainer: Codable {
    public var images: [PostImage]
}

public struct PostContainer: Codable {
    public var post: Post
}

public struct PostImageContainer: Codable {
    public var image: PostImage?
}
