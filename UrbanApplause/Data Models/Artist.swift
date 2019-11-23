//
//  Artist.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct Artist: Codable {
    var id: Int
    var signing_name: String?
    var first_name: String?
    var last_name: String?
    var hash_pass: String?
    var bio: String?
    var createdAt: Date?
    var Posts: [Post]?
}

struct ArtistsContainer: Codable {
    var artists: [Artist]
}
extension Artist: Equatable {
    
}

struct ArtistContainer: Codable {
    var artist: Artist
}
