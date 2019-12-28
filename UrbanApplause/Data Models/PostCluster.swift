//
//  PostCluster.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

class PostCluster: NSObject, Codable {
    var cluster_id: Int
    var count: Int
    var centroid: Coordinate
    var bounding_diagonal: PostGISBoundingDiagonal
    var cover_post_id: Int
    var cover_image: PostImage // use as backup in case thumbnail isn't ready yet
    var cover_image_thumb: PostImageThumbnail?
}

struct PostGISBoundingDiagonal: Codable {
    var coordinates: [[Double]] // [[lat,lng],[lat,lng]]
    var type: String
}

struct PostClustersContainer: Codable {
    var post_clusters: [PostCluster]
}

extension PostCluster: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: centroid.latitude, longitude: centroid.longitude)
    }
    
    var title: String? {
        return ""
    }
}
