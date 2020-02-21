//
//  PostQuery.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct PostQuery {
    public var page: Int
    public var limit: Int
    public var userId: Int?
    public var applaudedBy: Int?
    public var visitedBy: Int?
    public var artistId: Int?
    public var artistGroupId: Int?
    public var search: String?
    public var collectionId: Int?
    public var proximity: ProximityFilter?
    public var bounds: GeoBoundsFilter?
    public var include: [String]
    
    public init(page: Int = 0,
                limit: Int = 100,
                userId: Int? = nil,
                applaudedBy: Int? = nil,
                visitedBy: Int? = nil,
                artistId: Int? = nil,
                artistGroupId: Int? = nil,
                search: String? = nil,
                collectionId: Int? = nil,
                proximity: ProximityFilter? = nil,
                bounds: GeoBoundsFilter? = nil,
                include: [String] = []) {
        
        self.page = page
        self.limit = limit
        self.userId = userId
        self.applaudedBy = applaudedBy
        self.visitedBy = visitedBy
        self.artistId = artistId
        self.artistGroupId = artistGroupId
        self.search = search
        self.collectionId = collectionId
        self.proximity = proximity
        self.bounds = bounds
        self.include = include
    }
    
    public func makeURLParams() -> Parameters {
        let query = self
        var params = Parameters()
        params["page"] = String(query.page)
        params["limit"] = String(query.limit)
        if let id = query.userId {
            params["userId"] = String(id)
        }
        if let id = query.applaudedBy {
            params["clappedBy"] = String(id)
        }
        if let id = query.visitedBy {
            params["visitedBy"] = String(id)
        }
        if let id = query.artistId {
            params["artistId"] = String(id)
        }
        if let id = query.artistGroupId {
            params["artistGroupId"] = String(id)
        }
        if let searchQuery = query.search, searchQuery.count > 0 {
            params["search"] = searchQuery
        }
        if let id = query.collectionId {
            params["collectionId"] = String(id)
        }
        if let filter = query.proximity {
            params["lat"] = String(filter.target.latitude)
            params["lng"] = String(filter.target.longitude)
            params["max_distance"] = "\(filter.maxDistanceKm)"
        }
        if let bounds = query.bounds {
            params["lat1"] = String(bounds.neCoord.latitude)
            params["lng1"] = String(bounds.neCoord.longitude)
            params["lat2"] = String(bounds.swCoord.latitude)
            params["lng2"] = String(bounds.swCoord.longitude)
        }
        if query.include.count > 0 {
            params["include"] = query.include.joined(separator: ",")
        }
        return params
    }
}
