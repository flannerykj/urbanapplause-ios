//
//  Post.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

public class Post: NSObject, Codable {
    public var id: Int
    // public var title: String?
    public var content: String?
    public var active: Bool
    public var createdAt: Date?
    public var updatedAt: Date?
    public var UserId: Int
    public var is_location_fixed: Bool
    public var surface_type: String?
    
    public var PostImages: [PostImage]?
    public var Artists: [Artist]?
    public var Location: Location?
    public var User: User?
    public var Claps: [Clap]?
    public var Visits: [Visit]?
    public var Collections: [Collection]?
    public var Comments: [Comment]?
}

public struct PostQuery {
    public var page: Int
    public var limit: Int
    public var userId: Int?
    public var applaudedBy: Int?
    public var visitedBy: Int?
    public var artistId: Int?
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
        self.search = search
        self.collectionId = collectionId
        self.proximity = proximity
        self.bounds = bounds
        self.include = include
    }
}

extension Post: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        guard let coords = self.Location?.coordinates else {
            return CLLocationCoordinate2D()
        }
        return CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
    }
    
    public var title: String? {
        return (self.Artists ?? []).map { $0.signing_name ?? "Unknown" }.joined(separator: ", ")
    }
}
