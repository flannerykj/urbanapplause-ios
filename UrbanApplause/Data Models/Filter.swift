//
//  Filter.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-24.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

protocol Filter {
    associatedtype ValueType
    func doesMatchItem(_ item: Post) -> Bool
}

class PostFilter: Filter {
    typealias ValueType = Post
    
    func doesMatchItem(_ item: Post) -> Bool {
        fatalError("This should be overriden")
    }
}

class PostUserFilter: PostFilter {
    var selectedUser: User?
    
    override func doesMatchItem(_ item: Post) -> Bool {
        guard let selectedUser = self.selectedUser else {
            return true // don't apply filter if no user selected
        }
        return item.User?.id == selectedUser.id
    }
}
