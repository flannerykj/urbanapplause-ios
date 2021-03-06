//
//  PostListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

public class PostListViewModel: ListViewModel {
    public typealias T = Post
    var appContext: AppContext

    public var _listItems: [Post] = []
    
    public var didUpdateListItems: (([IndexPath], [IndexPath], Bool) -> Void)?
    public var didSetLoading: ((Bool) -> Void)?
    public var didSetErrorMessage: ((String?) -> Void)?
    public var showOptionToLoadMore: Bool {
        return false
    }
    public var currentPage: Int = 0

    
    init(posts: [Post], appContext: AppContext) {
        self.appContext = appContext
        self._listItems = posts
    }

    public func fetchListItems(forceReload: Bool) {
        self.isLoading = false
        self.didUpdateListItems?([], [], true)
    }
    
    public var errorMessage: String? = nil {
        didSet {
            self.didSetErrorMessage?(errorMessage)
        }
    }
    public var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
}
