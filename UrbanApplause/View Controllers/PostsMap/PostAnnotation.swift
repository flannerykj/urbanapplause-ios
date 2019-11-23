//
//  PostAnnotation.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-02.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

class PostAnnotation: MKPointAnnotation {

    var post: Post

    init(post: Post, coordinate: CLLocationCoordinate2D) {
        self.post = post

        super.init()

        self.coordinate = coordinate
        self.title = "post title"
        self.subtitle = "post subtitle"
    }
}
