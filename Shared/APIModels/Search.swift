//
//  Search.swift
//  Shared
//
//  Created by Flann on 2021-02-13.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation


public class SearchResults: Codable {
    public var artists: [Artist]?
    public var posts: [Post]?
    public var users: [User]?
    public var locations: [Location]?
    public var collections: [Collection]?
    public var artist_groups: [ArtistGroup]?
}

public class SearchResultsResponse: Codable {
    public var results: SearchResults
}
