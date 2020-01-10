//
//  PostImage.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

fileprivate let log = DHLogger.self

public class PostImage: File {
    public var id: Int
    public var storage_location: String
    public var filename: String
    public var mimetype: String?
    public var createdAt: Date?
    public var updatedAt: Date?
    public var PostId: Int?
    public var UserId: Int?
    public var thumbnail: PostImageThumbnail?
    
    enum CodingKeys: String, CodingKey {
        case id, storage_location, filename, mimetype, createdAt, updatedAt, PostId, UserId,
        thumbnail = "PostImageThumbnail"
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        do {
            id = try values.decode(Int.self, forKey: .id)
        } catch {
            log.warning("Failed to decode post id as Int")
            let idString = try values.decode(String.self, forKey: .id)
            guard let id = Int(idString) else {
                throw error
            }
            self.id = id
        }
        do {
            PostId = try values.decode(Int.self, forKey: .PostId)
        } catch {
            log.warning("Failed to decode PostId as Int")
            let idString = try values.decode(String.self, forKey: .PostId)
            guard let id = Int(idString) else {
                throw error
            }
            self.PostId = id
        }
        do {
            UserId = try values.decode(Int.self, forKey: .UserId)
        } catch {
            log.warning("Failed to decode UserId as Int")
            let idString = try values.decode(String.self, forKey: .UserId)
            guard let id = Int(idString) else {
                throw error
            }
            UserId = id
        }
        storage_location = try values.decode(String.self, forKey: .storage_location)
        filename = try values.decode(String.self, forKey: .filename)
        mimetype = try values.decodeIfPresent(String.self, forKey: .mimetype)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        thumbnail = try values.decodeIfPresent(PostImageThumbnail.self, forKey: .thumbnail)
    }
}

public struct PostImagesContainer: Codable {
    public var images: [PostImage]
}

public struct PostImageThumbnail: File {
    public var filename: String
    public var mimetype: String?
    public var storage_location: String
    
    public init(storage_location: String) {
        self.filename = UUID().uuidString
        self.storage_location = storage_location
    }
}
