//
//  ArtistListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

public class ArtistListViewModel: ListViewModel {
    public typealias T = Artist
    var appContext: AppContext

    public var _listItems: [Artist] = []
    
    public var didUpdateListItems: (([IndexPath], [IndexPath], Bool) -> Void)?
    public var didSetLoading: ((Bool) -> Void)?
    public var didSetErrorMessage: ((String?) -> Void)?
    public var showOptionToLoadMore: Bool {
        return false
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
    
    public var currentPage: Int = 0
    
    init(appContext: AppContext) {
        self.appContext = appContext
    }
}
