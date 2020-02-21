//
//  Artist.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct Artist: Codable {
    public var id: Int
    public var signing_name: String?
    public var first_name: String?
    public var last_name: String?
    public var hash_pass: String?
    public var bio: String?
    public var createdAt: Date?
    public var Posts: [Post]?
    public var ArtistGroups: [ArtistGroup]?
}

public extension Artist {
    static var includeParams: [String] {
        return ["posts", "artist_groups"]
    }
}
extension Artist: Equatable {}

public struct ArtistsContainer: Codable {
    public var artists: [Artist]
}

public struct ArtistContainer: Codable {
    public var artist: Artist
}
