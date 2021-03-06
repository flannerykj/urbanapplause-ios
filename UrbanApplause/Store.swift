//
//  Store.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

class Store {
    var user = DataState<User>()
    var collections = DataState<[Collection]>()
    var experiments = DataState<[String]>()
    
    init() {}
}

struct DataState<T> {
    var needsUpdate: Bool
    var isLoading: Bool
    var data: T?
    var errorMessage: String?
    
    init() {
        self.isLoading = false
        self.needsUpdate = true
    }
}
