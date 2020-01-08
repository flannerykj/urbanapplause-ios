//
//  UIViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
extension UIViewController {
    func showAlertForLoginRequired(desiredAction: String, appContext: AppContext) {
        let alert = UIAlertController(title: "You must be logged in to \(desiredAction).", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Create an account", style: .default, handler: { _ in
            self.showAuth(isNewUser: true, appContext: appContext)
        }))
        alert.addAction(UIAlertAction(title: "Log in", style: .default, handler: { _ in
            self.showAuth(isNewUser: false, appContext: appContext)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    func showAuth(isNewUser: Bool, appContext: AppContext) {
        let controller = AuthViewController(isNewUser: isNewUser, appContext: appContext)
        self.present(UINavigationController(rootViewController: controller), animated: true, completion: nil)
    }
    
    fileprivate var alertCenterSourceRect: CGRect {
        return CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
    }
    func showAlert(title: String? = nil, message: String?, onDismiss: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            ac.dismiss(animated: true, completion: nil)
            onDismiss?()
        })
        ac.addAction(okAction)
        self.presentAlertInCenter(ac)
    }
    
    func presentAlertInCenter(_ alertController: UIAlertController,
                              animated: Bool = true, completion: (() -> Void)? = nil) {
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertForDeniedPermissions(permissionType: String,
                                       onDismiss: (() -> Void)? = nil,
                                       appContext: AppContext) {
        
        let instructions = "Please enable \(permissionType) permissions in your Settings"
        let alert = UIAlertController(title: instructions, message: nil, preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
            onDismiss?()
        })
        alert.addAction(cancel)
        
        if let sharedApp = appContext.sharedApplication {
            let goToSettings = UIAlertAction(title: "Go to settings", style: .default, handler: { _ in
                appContext.openSettings { success in
                    if success {
                        alert.dismiss(animated: true, completion: nil)
                    }
                }
            })
            alert.addAction(goToSettings)
        }
        
        self.presentAlertInCenter(alert)
    }
}

protocol UnsavedChangesController: UIViewController {
    var hasUnsavedChanges: Bool { get set }
    var confirmDiscardChangesTitle: String { get }
    var confirmDiscardChangesMessage: String { get }
}
extension UnsavedChangesController {
    var confirmDiscardChangesTitle: String { return "Are you sure you want to leave?" }
    var confirmDiscardChangesMessage: String { return "You have unsaved changes that will be discarded." }
}

extension UnsavedChangesController {
    func confirmDiscardChanges() {
        if !hasUnsavedChanges {
            self.dismiss(animated: true, completion: nil)
            return
        }
        let alertController = UIAlertController(title: self.confirmDiscardChangesTitle,
                                                message: self.confirmDiscardChangesMessage,
                                                preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(proceedAction)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = alertCenterSourceRect
        present(alertController, animated: true, completion: nil)
    }
}
extension UIViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if let nav = presentedViewController as? UINavigationController,
            let controller = nav.viewControllers.first as? UnsavedChangesController {
            controller.confirmDiscardChanges()
        } else if let controller = presentedViewController as? UnsavedChangesController {
            controller.confirmDiscardChanges()
        }
    }
}
