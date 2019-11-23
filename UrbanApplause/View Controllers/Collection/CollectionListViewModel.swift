//
//  CollectionListViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-25.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

class CollectionListViewModel {
    var userId: Int
    var mainCoordinator: MainCoordinator
    
    var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
    var collections = [Collection]() {
        didSet {
            didUpdateData?(collections)
        }
    }
    var errorMessage: String? = nil {
        didSet {
           didSetErrorMessage?(errorMessage)
        }
    }
    var didUpdateData: (([Collection]) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    
    init(userId: Int, mainCoordinator: MainCoordinator) {
        self.userId = userId
        self.mainCoordinator = mainCoordinator
    }
    
    func getCollections() {
        guard !isLoading else {
            return
        }
        errorMessage = nil
        isLoading = true
        let endpoint = PrivateRouter.getCollections(userId: userId, postId: nil)
        
        _ = mainCoordinator.networkService.request(endpoint) { [weak self] (result: UAResult<CollectionsContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.isLoading = false
                    self?.errorMessage = error.userMessage
                case .success(let collectionsContainer):
                    self?.isLoading = false
                    self?.collections = collectionsContainer.collections
                }
            }
            
        }
    }
}
