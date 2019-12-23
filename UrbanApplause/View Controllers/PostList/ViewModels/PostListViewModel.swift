//
//  PostListModelProtocol.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

protocol PostListViewModel: class {
    var _posts: [Post] { get set }
    var didUpdateData: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)? { get set }
    var didSetLoading: ((Bool) -> Void)? { get set }
    
    var didSetErrorMessage: ((String?) -> Void)? { get set }
    var showOptionToLoadMore: Bool { get }
    func getPosts(forceReload: Bool)
    var errorMessage: String? { get set }
    var isLoading: Bool { get set }
    var currentPage: Int { get set }
}
extension PostListViewModel {
    var posts: [Post] { return self._posts }
    
    func removePost(atIndex index: Int) {
        self._posts.remove(at: index)
    }
    
    func updatePost(atIndex index: Int, updatedPost: Post) {
        self._posts[index] = updatedPost
    }
    
    func getNewIndexPaths(forAddedPosts posts: [Post]) -> [IndexPath] {
        let startIndex = posts.count
        let endIndex = startIndex + posts.count
        let newIndexPaths = (startIndex ..< endIndex).map { IndexPath(row: $0, section: 0)}
        return newIndexPaths
    }
}
