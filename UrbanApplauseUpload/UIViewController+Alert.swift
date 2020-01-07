//
//  UIViewController+Alert.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlertForDeniedPermissions(permissionType: String, onDismiss: (() -> Void)? = nil) {
        let instructions = "Please enable \(permissionType) permissions in your Settings"
        let alert = UIAlertController(title: instructions, message: nil, preferredStyle: .alert)
        let goToSettings = UIAlertAction(title: "Go to settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
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
