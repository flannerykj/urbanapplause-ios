//
//  UIViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
public extension UIViewController {
    fileprivate var alertCenterSourceRect: CGRect {
        return CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
    }
    func showAlert(title: String? = nil, message: String?, onDismiss: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: Strings.OKButtonTitle, style: .default, handler: { _ in
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
                                       handleOpenSettings: (() -> Void)?) {
        
        let title = String(format: Strings.MissingPermissionsErrorMessage, permissionType)
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        let cancel = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
            onDismiss?()
        })
        alert.addAction(cancel)
        
        if let onOpenSettings = handleOpenSettings {
            let goToSettings = UIAlertAction(title: Strings.GoToSettingsButtonTitle, style: .default, handler: { _ in
                onOpenSettings()
            })
            alert.addAction(goToSettings)
        }
        
        self.presentAlertInCenter(alert)
    }
}

public protocol UnsavedChangesController: UIViewController {
    var hasUnsavedChanges: Bool { get set }
    var confirmDiscardChangesTitle: String { get }
    var confirmDiscardChangesMessage: String { get }
}
public extension UnsavedChangesController {
    var confirmDiscardChangesTitle: String { return Strings.ConfirmDiscardChangesTitle }
    var confirmDiscardChangesMessage: String { return Strings.UnsavedChangesWarning }
}

public extension UnsavedChangesController {
    func confirmDiscardChanges() {
        if !hasUnsavedChanges {
            self.dismiss(animated: true, completion: nil)
            return
        }
        let alertController = UIAlertController(title: self.confirmDiscardChangesTitle,
                                                message: self.confirmDiscardChangesMessage,
                                                preferredStyle: .actionSheet)
        
        let proceedAction = UIAlertAction(title: Strings.DiscardButtonTitle, style: .destructive, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        
        let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)
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
