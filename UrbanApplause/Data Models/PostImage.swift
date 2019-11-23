//
//  PostImage.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

class PostImage: File {
    var id: Int
    var storage_location: String
    var filename: String    
    var mimetype: String?
    var createdAt: Date?
    var updatedAt: Date?
    var PostId: Int?
    var UserId: Int?
    var thumbnail: PostImageThumbnail?
    
    enum CodingKeys: String, CodingKey {
        case id, storage_location, filename, mimetype, createdAt, updatedAt, PostId, UserId,
        thumbnail = "PostImageThumbnail"
    }

    required init(from decoder: Decoder) throws {
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

struct PostImagesContainer: Codable {
    var images: [PostImage]
}

struct PostImageThumbnail: File {
    var filename: String
    var mimetype: String?
    var storage_location: String
    
    init(storage_location: String) {
        self.filename = UUID().uuidString
        self.storage_location = storage_location
    }
}
