//
//  MainCoordinator.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol MainCoordinatorDelegate: AnyObject {
    func mainCoordinator(setRootController controller: UIViewController)
}

class MainCoordinator: NSObject {
    weak var delegate: MainCoordinatorDelegate?
    private var rootController: UIViewController? {
        didSet {
            if let controller = rootController {
                delegate?.mainCoordinator(setRootController: controller)
            }
        }
    }
    private(set) var keychainService: KeychainService
    private(set) var userDefaults: UserDefaults
    
    private(set) var store = Store()
    lazy private(set) var authService = AuthService(keychainService: keychainService)
    lazy private(set) var fileCache: FileService = FileService()
    lazy private(set) var networkService: NetworkService = {
        var headers: [String: String] = [:]
        do {
            let authTokens: AuthResponse =
                try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            headers["Authorization"] = "Bearer \(authTokens.access_token)"
        } catch {
            log.warning(error)
        }
        return NetworkService(customHeaders: headers, handleAuthError: { serverError in
           self.endSession()
        })
    }()

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
        } catch {
        }
        navigateToApp()
    }
    public func endSession() {
        // Called when user logs out, or session ends and logs out forcefully.
        authService.endSession()
        store = Store()
        self.navigateToApp()
    }
    
    // MARK: - Private Methods
    private func navigateToApp() {
        store.user.data = authService.authUser
        let root = TabBarController(store: store, mainCoordinator: self)
        switchRootViewController(viewController: root)
    }
    
    private func switchRootViewController(viewController: UIViewController) {
        self.rootController = viewController
    }
}
