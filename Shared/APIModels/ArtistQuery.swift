//
//  ArtistQuery.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct ArtistQuery {
    public var page: Int
    public var limit: Int
    public var artistGroupId: Int? // Artists who belong to this group
    public var geoBounds: GeoBoundsFilter? // Artists who've authored a work in this area
    public var search: String?
    public var include: [String]
    
    public init(page: Int = 0,
                limit: Int = 100,
                artistGroupId: Int? = nil,
                search: String? = nil,
                // geoBounds: GeoBoundsFilter? = nil,
                include: [String] = []) {
        
        self.page = page
        self.limit = limit
        self.artistGroupId = artistGroupId
        self.search = search
        // self.geoBounds = geoBounds
        self.include = include
    }
    
    public func makeURLParams() -> Parameters {
        let query = self
        var params = Parameters()
        params["page"] = String(query.page)
        params["limit"] = String(query.limit)
        if let id = query.artistGroupId {
            params["artistGroupId"] = String(id)
        }
        if let searchQuery = query.search, searchQuery.count > 0 {
            params["search"] = searchQuery
        }
//        if let bounds = query.bounds {
//            params["lat1"] = String(bounds.neCoord.latitude)
//            params["lng1"] = String(bounds.neCoord.longitude)
//            params["lat2"] = String(bounds.swCoord.latitude)
//            params["lng2"] = String(bounds.swCoord.longitude)
//        }
        if query.include.count > 0 {
            params["include"] = query.include.joined(separator: ",")
        }
        return params
    }
}
