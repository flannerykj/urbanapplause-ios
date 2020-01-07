//
//  UIViewController+UnsavedChanges.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(title: String? = nil, message: String?, onDismiss: (() -> Void)? = nil) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            ac.dismiss(animated: true, completion: nil)
            onDismiss?()
        })
        ac.addAction(okAction)
        self.presentAlertInCenter(ac)
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
    
    var alertCenterSourceRect: CGRect {
        return CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
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
