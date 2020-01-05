//
//  ForgotPasswordViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import UrbanApplauseShared

class ForgotPasswordViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                self.submitButton.showLoading()
            } else {
                self.submitButton.hideLoading()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var emailField: UATextField = {
        let icon = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        icon.image = UIImage(systemName: "envelope")
        
        let field = UATextField()
        field.leftView = icon
        field.leftViewMode = .always
        field.placeholder = "Email address"
        field.autocapitalizationType = .none
        field.textContentType = .emailAddress
        field.autocorrectionType = .no
        field.keyboardType = .emailAddress
        field.tag = 0
        field.returnKeyType = .go
        field.delegate = self
        return field
    }()
    
    lazy var submitButton = UAButton(type: .primary, title: "Submit", target: self, action: #selector(submit(_:)))
    lazy var errorView = ErrorView()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [emailField, errorView, submitButton])
        
        stackView.addArrangedSubview(submitButton)
        stackView.layoutMargins = StyleConstants.defaultMarginInsets
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Reset password"
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGray6
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            stackView.leftAnchor.constraint(equalTo: view.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.rightAnchor)
        ])
        emailField.becomeFirstResponder()
    }

    @objc func submit(_ sender: Any) {
        guard let email = emailField.text, email.count > 0 else {
            self.showAlert(message: "Please enter your email")
            return
        }
        self.isLoading = true
        self.errorView.errorMessage = nil
        self.emailField.resignFirstResponder()
        let endpoint = AuthRouter.resetPassword(email: email)
        _ = mainCoordinator.networkService.request(endpoint) { (result: UAResult<MessageContainer>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    let successMessage = "An email has been sent to \(email) with instructions to reset your password."
                    self.showAlert(title: "Success!",
                                   message: successMessage, onDismiss: {
                        self.navigationController?.popViewController(animated: true)
                    })
                case .failure(let error):
                    self.errorView.errorMessage = error.userMessage
                }
            }
        }
    }
}

struct MessageContainer: Codable {
    var message: String
}
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       // Try to find next responder
        switch textField.returnKeyType {
        case .go:
            submit(textField)
        default:
            textField.resignFirstResponder()
        }
       // Do not add a line break
       return false
    }
}
