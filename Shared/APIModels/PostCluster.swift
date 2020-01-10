//
//  PostCluster.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

public class PostCluster: NSObject, Codable {
    public var cluster_id: Int
    public var count: Int
    public var centroid: Coordinate
    public var bounding_diagonal: PostGISBoundingDiagonal
    public var cover_post_id: Int
    public var cover_image: PostImage // use as backup in case thumbnail isn't ready yet
    public var cover_image_thumb: PostImageThumbnail?
}

public struct PostGISBoundingDiagonal: Codable {
    public var coordinates: [[Double]] // [[lat,lng],[lat,lng]]
    public var type: String
}

public struct PostClustersContainer: Codable {
    public var post_clusters: [PostCluster]
}

extension PostCluster: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: centroid.latitude, longitude: centroid.longitude)
    }
    
    public var title: String? {
        return ""
    }
}
