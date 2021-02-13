//
//  PasswordResetViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-09.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Shared
import Combine

protocol PasswordResetViewControllerDelegate: AnyObject {
    func didResetPassword()
}
class PasswordResetViewController: UIViewController {
    weak var delegate: PasswordResetViewControllerDelegate?
    
    private let appContext: AppContext
    private let resetToken: String
    private let email: String
    
    init(appContext: AppContext, resetToken: String, email: String) {
        self.appContext = appContext
        self.resetToken = resetToken
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
//
//    lazy var toggleVisibilityButton: IconButton = {
//        let button = IconButton(image: UIImage(systemName: "eye.slash.fill"),
//                                activeImageColor: .red,
//                                size: CGSize(width: 24, height: 24),
//                                target: self, action: #selector(togglePasswordVisibility(sender:)))
//        button.selectedImage = UIImage(systemName: "eye.fill")
//        return button
//    }()
//
//    lazy var toggleVisibilityButton2: IconButton = {
//        let button = IconButton(image: UIImage(systemName: "eye.slash.fill"),
//                                activeImageColor: .red,
//                                size: CGSize(width: 24, height: 24),
//                                target: self, action: #selector(togglePasswordVisibility(sender:)))
//        button.selectedImage = UIImage(systemName: "eye.fill")
//        return button
//    }()
//
    private lazy var passwordField: UATextField = {
        let field = UATextField()
        field.placeholder = "New password"
        field.isSecureTextEntry = true
//        field.rightView = toggleVisibilityButton
        return field
    }()
    
    private lazy var passwordConfirmationField: UATextField = {
        let field = UATextField()
        field.placeholder = "Confirm your new password"
        field.isSecureTextEntry = true
//        field.rightView = toggleVisibilityButton2
        return field
    }()
    
    private lazy var submitButton = UAButton(type: .primary, title: "Submit", target: self, action: #selector(submitButtonTapped(_:)))

    private lazy var errorMessageLabel: UILabel = {
        let label = UILabel(type: .error)
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false 
        let stackView = UIStackView(arrangedSubviews: [passwordField, passwordConfirmationField, errorMessageLabel, submitButton, spacer])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.title = "Reset your password"
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    @objc func togglePasswordVisibility(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            // show password
            passwordField.isSecureTextEntry = false
        } else {
            // hide password
            passwordField.isSecureTextEntry = true
        }
    }
    
    @objc func submitButtonTapped(_ sender: UAButton) {
        guard let newPassword = passwordField.text, !newPassword.isEmpty else {
            errorMessageLabel.text = "Password field cannot be empty"
            return
        }
        guard newPassword == passwordConfirmationField.text else {
            errorMessageLabel.text = "Your passwords must match"
            return
        }
        
        submitButton.showLoading()
        _ = appContext.networkService.request(AuthRouter.updatePassword(newPassword: newPassword, email: email, resetToken: resetToken), completion: { [weak self] (result: UAResult<AuthUserResponse>) in
            self?.submitButton.hideLoading()
            switch result {
            case .failure(let error):
                if let serverError = error as? UAServerError {
                    self?.errorMessageLabel.text = serverError.userMessage
                } else {
                    self?.errorMessageLabel.text = "Unable to reset password."
                }
            case .success:
                self?.dismiss(animated: true, completion: { [weak self] in
                    self?.delegate?.didResetPassword()
                })
            }
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
