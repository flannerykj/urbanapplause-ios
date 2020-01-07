//
//  UIViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
extension UIViewController {
    func showAlertForLoginRequired(desiredAction: String, mainCoordinator: MainCoordinator) {
        let alert = UIAlertController(title: "You must be logged in to \(desiredAction).", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Create an account", style: .default, handler: { _ in
            self.showAuth(isNewUser: true, mainCoordinator: mainCoordinator)
        }))
        alert.addAction(UIAlertAction(title: "Log in", style: .default, handler: { _ in
            self.showAuth(isNewUser: false, mainCoordinator: mainCoordinator)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func showAuth(isNewUser: Bool, mainCoordinator: MainCoordinator) {
        let controller = AuthViewController(isNewUser: isNewUser, mainCoordinator: mainCoordinator)
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    

    func showAlertForDeniedPermissions(permissionType: String, onDismiss: (() -> Void)? = nil) {
        let instructions = "Please enable \(permissionType) permissions in your Settings"
        let alert = UIAlertController(title: instructions, message: nil, preferredStyle: .alert)
        let goToSettings = UIAlertAction(title: "Go to settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    log.debug("Settings opened: \(success)")
                    alert.dismiss(animated: true, completion: nil)
                })
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
            onDismiss?()
        })
        alert.addAction(cancel)
        alert.addAction(goToSettings)
        self.presentAlertInCenter(alert)
    }
    
    func presentAlertInCenter(_ alertController: UIAlertController,
                              animated: Bool = true, completion: (() -> Void)? = nil) {
        self.present(alertController, animated: true, completion: nil)
    }
}



