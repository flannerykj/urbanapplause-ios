//
//  ArtistGroupDetailViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

class ArtistGroupDetailViewModel {
    
    public var onSetData: ((ArtistGroup?) -> Void)?
    public var onSetLoading: ((Bool) -> Void)?
    public var onSetError: ((String?) -> Void)?
    
    private(set) var groupID: Int
    private var appContext: AppContext
    
    private(set) var data: ArtistGroup? {
        didSet {
            onSetData?(self.data)
        }
    }
    private(set) var errorMessage: String? {
        didSet {
            onSetError?(self.errorMessage)
        }
    }
    private(set) var isLoading: Bool = false {
        didSet {
            onSetLoading?(self.isLoading)
        }
    }
    
    init(groupID: Int, group: ArtistGroup?, appContext: AppContext) {
        self.groupID = groupID
        self.data = group
        self.appContext = appContext
    }
    
    func fetchArtistGroup() {
        guard !isLoading else { return }
        self.isLoading = true
        let endpoint = PrivateRouter.getArtistGroup(groupId: self.groupID)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<ArtistGroupContainer>) in
            self.isLoading = false
            switch result {
            case .success(let container):
                self.data = container.artist_group
            case .failure(let error):
                log.error(error)
                self.errorMessage = error.userMessage
            }
        }
    }
}
