//
//  AppContext.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

protocol AppContextDelegate: AnyObject {
    func appContext(setRootController controller: UIViewController)
    func appContextOpenSettings(completion: @escaping (Bool) -> Void)
}

class AppContext: NSObject {
    weak var sharedApplication: UIApplication?
    weak var delegate: AppContextDelegate?
    
    private var rootController: UIViewController? {
        didSet {
            if let controller = rootController {
                delegate?.appContext(setRootController: controller)
            }
        }
    }
    private(set) var keychainService: KeychainService
    private(set) var userDefaults: UserDefaults
    
    private(set) var store = Store()
    lazy private(set) var authService = AuthService(keychainService: keychainService)
    lazy private(set) var fileCache: FileService = FileService()
    
    lazy private(set) var networkService = APIClient(customHeaders: customHeaders, handleAuthError: { serverError in
           self.endSession()
        })

    var customHeaders: [String: String] {
        var headers: [String: String] = [:]
        do {
            let authTokens: AuthResponse =
                try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            headers["Authorization"] = "Bearer \(authTokens.access_token)"
        } catch {
            log.warning(error)
        }
        return headers
    }

    init(keychainService: KeychainService = KeychainService(),
         userDefaults: UserDefaults = UserDefaults.standard) {
        
        self.keychainService = keychainService
        self.userDefaults = userDefaults
        super.init()
    }
    // MARK: - Public Methods
    func start() {
        navigateToApp()
    }

    public func startSession(authResponse: AuthResponse) {
        // Called when user logs in. Not called if valid token already in keychain when app launches.
        do {
            try authService.beginSession(authResponse: authResponse)
            networkService.setCustomHeaders(customHeaders)
        } catch {
        }
        navigateToApp()
    }
    public func endSession() {
        // Called when user logs out
        authService.endSession()
        store = Store()
        self.navigateToApp()
    }
    
    public var canOpenSettings: Bool {
        return delegate != nil
    }
    public func openSettings(completion: @escaping (Bool) -> Void) {
        delegate?.appContextOpenSettings(completion: completion)
    }
    
    // MARK: - Private Methods
    private func navigateToApp() {
        store.user.data = authService.authUser
        let root = TabBarController(store: store, appContext: self)
        switchRootViewController(viewController: root)
    }
    
    private func switchRootViewController(viewController: UIViewController) {
        self.rootController = viewController
    }
    
}
