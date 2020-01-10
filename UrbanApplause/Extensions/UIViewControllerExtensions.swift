//
//  UIViewControllerExtensions.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

extension UIViewController {
    func showAlertForLoginRequired(desiredAction: String, appContext: AppContext) {
        let alert = UIAlertController(title: Strings.MustBeLoggedInToPerformAction(desiredAction),
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.CreateAccountButtonTitle, style: .default, handler: { _ in
            self.showAuth(isNewUser: true, appContext: appContext)
        }))
        alert.addAction(UIAlertAction(title: Strings.LogInButtonTitle, style: .default, handler: { _ in
            self.showAuth(isNewUser: false, appContext: appContext)
        }))
        alert.addAction(UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func showAuth(isNewUser: Bool, appContext: AppContext) {
        let controller = AuthViewController(isNewUser: isNewUser, appContext: appContext)
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    func showAlertForDeniedPermissions(permissionType: String,
                                       onDismiss: (() -> Void)? = nil,
                                       showOpenSettingsButton: Bool = true) {
        
        var openSettingsCallback: (() -> Void)? = nil
        
        if showOpenSettingsButton,
            let settingsURL = URL(string: UIApplication.openSettingsURLString),
            UIApplication.shared.canOpenURL(settingsURL) {
            
            openSettingsCallback = {
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        onDismiss?()
                    })
                }
            }
        }
        showAlertForDeniedPermissions(permissionType: permissionType,
                                      onDismiss: onDismiss,
                                      handleOpenSettings: openSettingsCallback)
    }
}
