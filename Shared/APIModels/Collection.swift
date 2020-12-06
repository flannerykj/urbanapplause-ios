//
//  Collection.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct Collection: Codable {
    public var type: Gallery {
        return .custom(self)
    }
    
    public var id: Int
    public var title: String
    public var description: String?
    public var UserId: Int
    public var Posts: [Post]?
    public var is_public: Bool
    
    
    public init(title: String = "New collection", id: Int = 0, UserId: Int = 0, Posts: [Post] = []) {
        self.id = id
        self.title = title
        self.UserId = UserId
        self.Posts = Posts
        self.is_public = false
    }
}

// Question: way to avoid creating container type for each data type's api response?
public struct CollectionContainer: Codable {
    public var collection: Collection
}
public struct CollectionsContainer: Codable {
    public var collections: [Collection]
}
