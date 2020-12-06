//
//  GalleryCellViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import Shared

class GalleryCellViewModel: NSObject {
    var gallery: Gallery
    var posts: [Post]
    var isSelected: Bool = false
    
    init(galleryType: Gallery, posts: [Post]) {
        self.gallery = galleryType
        self.posts = posts
    }
}
