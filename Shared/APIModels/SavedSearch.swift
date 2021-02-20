//
//  SavedSearch.swift
//  Shared
//
//  Created by Flann on 2021-02-15.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation

public class SavedSearch: Codable {
    public var id: Int
    public var SavedSearchId: Int?
    public var UserId: Int?
    public var User: User?
    public var logical_operator: SavedSearchLogicalOperator
    public var SavedLocationSearches: [SavedLocationSearch]?
    public var SavedUserSearches: [SavedUserSearch]?
    public var SavedArtistSearches: [SavedArtistSearch]?
    public var SavedArtistGroupSearches: [SavedArtistGroupSearch]?
    public var SavedCollectionSearches: [SavedCollectionSearch]?
}
public enum SavedSearchLogicalOperator: String, Codable {
    case and, or, not
}

public class SavedSearchesResponse: Codable {
    public var saved_searches: [SavedSearch]
}

public class SavedSearchResponse: Codable {
    public var saved_search: SavedSearch
}

public class SavedLocationSearch: Codable {
    public var id: Int
    public var SavedSearchId: Int
    public var LocationId: Int
    public var location: Location?
    public var saved_distance_km_from_location: Int
    public var createdAt: Date
    public var updatedAt: Date
}
public class SavedUserSearch: Codable {
    public var id: Int
    public var SavedSearchId: Int
    public var SavedUserId: Int
    public var user: User?
    public var createdAt: Date
    public var updatedAt: Date
}
public class SavedArtistSearch: Codable {
    public var id: Int
    public var SavedSearchId: Int
    public var SavedArtistId: Int
    public var artist: Artist?
    public var createdAt: Date
    public var updatedAt: Date
}
public class SavedArtistGroupSearch: Codable {
    public var id: Int
    public var SavedSearchId: Int
    public var SavedArtistGroupId: Int
    public var artist_group: ArtistGroup?
    public var createdAt: Date
    public var updatedAt: Date
}
public class SavedCollectionSearch: Codable {
    public var id: Int
    public var SavedSearchId: Int
    public var SavedCollectionId: Int
    public var collection: Collection?
    public var createdAt: Date
    public var updatedAt: Date
}
