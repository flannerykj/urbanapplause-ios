//
//  ProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-28.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import Shared

class AccountViewController: FormViewController {
    var appContext: AppContext
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
        
        form +++ Section()
            <<< TextRow {
                $0.tag = "email"
                $0.title = Strings.EmailFieldLabel
                $0.value = appContext.store.user.data?.email
            }
            <<< TextRow {
                $0.tag = "username"
                $0.title = Strings.UsernameFieldLabel
                $0.value = appContext.store.user.data?.username
            }
            +++ Section()
                <<< ButtonRow {
                    $0.tag = "reset_password_button"
                    $0.onCellSelection { _, _ in
                        self.sendPasswordResetEmail()
                    }
                    $0.title = "Reset password"
                }.cellUpdate { cell, _ in
                    cell.textLabel?.textAlignment = .left
                }
        
        for row in form.rows {
            if row.tag == "email" || row.tag == "username" {
                row.baseCell.isUserInteractionEnabled = false
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    private func sendPasswordResetEmail() {
        guard let email = appContext.store.user.data?.email else {
            log.error("No email")
            return
        }
        let endpoint = AuthRouter.sendPasswordResetEmail(email: email)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<MessageContainer>) in
            DispatchQueue.main.async {
                // TODO: Show loading
                switch result {
                case .success:
                    let successMessage = Strings.AuthResetPasswordSuccessMessage(emailAddress: email)
                    self.showAlert(title: Strings.SuccessAlertTitle,
                                   message: successMessage)
                case .failure(let error):
                    var message: String = "Unable to reset password"
                    if let serverError = error as? UAServerError {
                        message = serverError.userMessage
                    }
                    self.showAlert(title: Strings.ErrorAlertTitle,
                                   message: message)
                }
            }
        }
    }
}
