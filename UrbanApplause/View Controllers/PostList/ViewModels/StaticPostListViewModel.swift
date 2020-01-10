//
//  StaticPostListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

class StaticPostListViewModel: PostListViewModel {
    internal var _posts = [Post]()
    
    var appContext: AppContext
    var didUpdateData: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    var showOptionToLoadMore: Bool {
        return false
    }
    var currentPage: Int = 0
    init(posts: [Post], appContext: AppContext) {
        self._posts = posts
        self.appContext = appContext
    }
    var errorMessage: String? = nil {
        didSet {
            self.didSetErrorMessage?(errorMessage)
        }
    }
    var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
    func getPosts(forceReload: Bool) {
        self.didUpdateData?([], [], true)
    }
}
