//
//  UserProfileViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//


import Foundation
import Shared

class UserProfileViewModel: NSObject {
    var didUpdateData: ((User?) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    
    private var appContext: AppContext
    
    private var userId: Int {
        didSet {
           fetchUser()
        }
    }
    private(set) var user: User? {
        didSet {
            didUpdateData?(user)
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

    init(userId: Int, user: User?, appContext: AppContext) {
        self.userId = userId
        self.appContext = appContext
    }
    public func setUser(_ user: User?) {
        self.user = user
    }
    
    func fetchUser() {
        self.isLoading = true
        let endpoint = PrivateRouter.getUser(id: userId)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<UserContainer>) in
            self.isLoading = false
            switch result {
            case .success(let container):
                self.user = container.user
            case .failure(let error):
                self.errorMessage = error.userMessage
            }
        }
    }
    
}
