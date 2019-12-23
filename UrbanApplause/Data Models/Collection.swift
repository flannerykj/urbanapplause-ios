//
//  Collection.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct Collection: Codable {
    var type: Gallery {
        return .custom(self)
    }
    
    var id: Int
    var title: String
    var description: String?
    var UserId: Int
    var Posts: [Post]?
}

// Question: way to avoid creating container type for each data type's api response?
struct CollectionContainer: Codable {
    var collection: Collection
}
struct CollectionsContainer: Codable {
    var collections: [Collection]
}
