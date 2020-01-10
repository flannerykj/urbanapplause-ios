//
//  ArtistProfileViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

class ArtistProfileViewModel: NSObject {
    var didUpdateData: ((Artist?) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    
    private var appContext: AppContext
    
    private var artistId: Int {
        didSet {
           fetchArtist()
        }
    }
    private(set) var artist: Artist? {
        didSet {
            didUpdateData?(artist)
        }
    }
    private(set) var isLoading: Bool = false {
        didSet {
            didSetLoading?(isLoading)
        }
    }
    private(set) var errorMessage: String? {
        didSet {
            didSetErrorMessage?(errorMessage)
        }
    }

    init(artistId: Int, artist: Artist?, appContext: AppContext) {
        self.artistId = artistId
        self.appContext = appContext
    }
    public func setArtist(_ artist: Artist?) {
        self.artist = artist
    }
    
    func fetchArtist() {
        self.isLoading = true
        let endpoint = PrivateRouter.getArtist(artistId: self.artistId)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<ArtistContainer>) in
            self.isLoading = false
            switch result {
            case .success(let container):
                self.artist = container.artist
            case .failure(let error):
                self.errorMessage = error.userMessage
            }
        }
    }
    
}
