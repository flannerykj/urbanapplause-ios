//
//  PostListModelProtocol.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public protocol ListViewModel: class {
    associatedtype T
    var _listItems: [T] { get set }
    
    // callbacks
    var didUpdateListItems: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)? { get set }
    var didSetLoading: ((Bool) -> Void)? { get set }
    var didSetErrorMessage: ((String?) -> Void)? { get set }
    
    var showOptionToLoadMore: Bool { get }
    func fetchListItems(forceReload: Bool)
    var errorMessage: String? { get set }
    var isLoading: Bool { get set }
    var currentPage: Int { get set }
}

public extension ListViewModel {
    var listItems: [T] { return self._listItems }
    
    func removeListItem(atIndex index: Int) {
        self._listItems.remove(at: index)
    }
    
    func updateListItem(atIndex index: Int, updatedItem: T) {
        self._listItems[index] = updatedItem
    }
    
    func getNewIndexPaths(forAddedItems items: [T]) -> [IndexPath] {
        let startIndex = items.count
        let endIndex = startIndex + items.count
        let newIndexPaths = (startIndex ..< endIndex).map { IndexPath(row: $0, section: 0)}
        return newIndexPaths
    }
}
