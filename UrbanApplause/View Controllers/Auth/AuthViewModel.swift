//
//  AuthViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

class AuthViewModel {
    var mainCoordinator: MainCoordinator
    
    private(set) var isLoading = false {
        didSet {
            self.didSetLoading?(isLoading)
        }
    }
    private(set) var isNewUser = false
    private(set) var errorMessage: String? {
        didSet {
            self.didSetErrorMessage?(errorMessage)
        }
    }

    var didUpdateData: ((_ added: [IndexPath], _ removed: [IndexPath], _ shouldReload: Bool) -> Void)?
    var didSetLoading: ((Bool) -> Void)?
    var didSetErrorMessage: ((String?) -> Void)?
    
    init(isNewUser: Bool, authContext: AuthContext, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.isNewUser = isNewUser
        if authContext == .tokenExpiry {
            self.errorMessage = "Your session has expired. Please log in again."
            self.didSetErrorMessage?(errorMessage)
        }
    }

    func submit(username: String?, email: String?, password: String?) {
        self.errorMessage = nil

        guard email != nil, password != nil else {
            errorMessage = "Email and password are required"
            return
        }
        if isNewUser {
            guard username != nil else {
                self.errorMessage = "Username is required"
                return
            }
        }
        self.isLoading = true
        let endpoint = AuthRouter.authenticate(email: email!,
                                               password: password!,
                                               username: username,
                                               newUser: isNewUser)
        _ = mainCoordinator.networkService.request(endpoint) { [weak self] (result: UAResult<AuthResponse>) in
            self?.isLoading = false
            switch result {
            case .success(let authResponse):
                DispatchQueue.main.async {
                    self?.mainCoordinator.startSession(authResponse: authResponse)
                }
            case .failure(let error):
                log.error(error)
                self?.errorMessage = error.userMessage
            }
        }
    }
}
