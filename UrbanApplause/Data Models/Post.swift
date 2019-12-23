//
//  Post.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

class Post: NSObject, Codable {
    var id: Int
    // var title: String?
    var content: String?
    var active: Bool
    var createdAt: Date?
    var updatedAt: Date?
    var UserId: Int
    
    var PostImages: [PostImage]?
    var Artists: [Artist]?
    var Location: Location?
    var User: User?
    var Claps: [Clap]?
    var Visits: [Visit]?
    var Collections: [Collection]?
    var Comments: [Comment]?
}

struct PostQuery {
    var page: Int
    var limit: Int
    var userId: Int?
    var applaudedBy: Int?
    var visitedBy: Int?
    var artistId: Int?
    var search: String?
    var collectionId: Int?
    var proximity: ProximityFilter?
    var bounds: GeoBoundsFilter?
    var include: [String]
    
    init(page: Int = 0,
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
    var coordinate: CLLocationCoordinate2D {
        guard let coords = self.Location?.coordinates else {
            return CLLocationCoordinate2D()
        }
        return CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
    }
    
    var title: String? {
        return (self.Artists ?? []).map { $0.signing_name ?? "Unknown" }.joined(separator: ", ")
    }
}
