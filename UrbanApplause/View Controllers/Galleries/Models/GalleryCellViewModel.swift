//
//  GalleryCellViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import UrbanApplauseShared

class GalleryCellViewModel: NSObject {
    var gallery: Gallery
    var posts: [Post]
    var isSelected: Bool = false
    
    init(galleryType: Gallery, posts: [Post]) {
        self.gallery = galleryType
        self.posts = posts
    }
}

/*
class Gallery: NSObject {
    var id: Int
    var title: String
    var icon: UIImage?
    var posts: [Post]
    var listViewModel: PostListViewModel
    
    var isSelected: Bool = false
    
    init(id: Int, title: String, icon: UIImage?, posts: [Post], listViewModel: PostListViewModel) {
        self.id = id
        self.title = title
        self.icon = icon
        self.posts = posts
        self.listViewModel = listViewModel
    }
} */
