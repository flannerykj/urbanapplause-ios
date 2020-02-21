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
    public var ArtistGroups: [ArtistGroup]?
    public var Location: Location?
    public var User: User?
    public var Claps: [Clap]?
    public var Visits: [Visit]?
    public var Collections: [Collection]?
    public var Comments: [Comment]?
}

public extension Post {
    class var includeParams: [String] {
        return ["location", "artists", "artist_groups", "post_images", "user", "claps", "collections", "comments", "visits"]
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
