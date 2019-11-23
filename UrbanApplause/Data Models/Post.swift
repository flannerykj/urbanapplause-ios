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
    var Applause: [Applause]?
    var Collections: [Collection]?
    var Comments: [Comment]?
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
