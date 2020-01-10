//
//  AuthViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

class AuthViewModel {
    var appContext: AppContext
    
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
    
    init(isNewUser: Bool, appContext: AppContext) {
        self.appContext = appContext
        self.isNewUser = isNewUser
    }

    func submit(username: String?, email: String?, password: String?) {
        self.errorMessage = nil

        guard email != nil else {
            errorMessage = Strings.MissingEmailError
            return
        }
        guard password != nil else {
            self.errorMessage = isNewUser ? Strings.MissingNewPasswordError : Strings.MissingPasswordError
            return
        }
        if isNewUser {
            guard username != nil else {
                self.errorMessage = isNewUser ? Strings.MissingNewUsernameError : Strings.MissingUsernameError
                return
            }
        }
        self.isLoading = true
        let endpoint = AuthRouter.authenticate(email: email!,
                                               password: password!,
                                               username: username,
                                               newUser: isNewUser)
        _ = appContext.networkService.request(endpoint) { [weak self] (result: UAResult<AuthResponse>) in
            self?.isLoading = false
            switch result {
            case .success(let authResponse):
                DispatchQueue.main.async {
                    self?.appContext.startSession(authResponse: authResponse)
                }
            case .failure(let error):
                log.error(error)
                self?.errorMessage = error.userMessage
            }
        }
    }
}
