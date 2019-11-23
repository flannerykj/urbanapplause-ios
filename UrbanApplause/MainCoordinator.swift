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
    lazy private(set) var networkService = NetworkService(mainCoordinator: self)

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
    public func endSession(authContext: AuthContext) {
        // Called when user logs out, or session ends and logs out forcefully.
        authService.endSession()
        store = Store()
        navigateToAuthentication(authContext: authContext)
    }
    
    // MARK: - Private Methods
    private func navigateToApp() {
        if authService.isAuthenticated, let user = authService.authUser {
            store.user.data = user
            let root = TabBarController(store: store, mainCoordinator: self)
            switchRootViewController(viewController: root)
        } else {
            navigateToAuthentication(authContext: .entrypoint)
            return
        }
    }
    
    private func switchRootViewController(viewController: UIViewController) {
        self.rootController = viewController
    }
    
    private func navigateToAuthentication(authContext: AuthContext) {
        let nav = UINavigationController(rootViewController: WelcomeViewController(store: store, mainCoordinator: self))
        switch authContext {
        case .userInitiated, .tokenExpiry:
            let authVC = AuthViewController(isNewUser: false, authContext: authContext, mainCoordinator: self)
            authVC.mainCoordinator = self
            nav.pushViewController(authVC, animated: false)
        case .entrypoint:
            if UserDefaults.getHasOpenedApp() {
                let authVC = AuthViewController(isNewUser: false, mainCoordinator: self)
                authVC.mainCoordinator = self
                nav.pushViewController(authVC, animated: false)
            } else {
                UserDefaults.setHasOpenedApp(true)
            }
        }
        switchRootViewController(viewController: nav)
    }
}
enum AuthDestination {
    case welcome, login, register
}

enum AuthContext {
    case entrypoint, userInitiated, tokenExpiry
}
