//
//  AuthViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2018-12-31.
//  Copyright © 2018 Flannery Jefferson. All rights reserved.
//

import UIKit
import SafariServices

class AuthViewController: UIViewController {
    private var viewModel: AuthViewModel
    var mainCoordinator: MainCoordinator
    
    init(isNewUser: Bool, authContext: AuthContext = .entrypoint, mainCoordinator: MainCoordinator) {
        self.viewModel = AuthViewModel(isNewUser: isNewUser, authContext: authContext, mainCoordinator: mainCoordinator)
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
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
        field.textContentType = .username
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .emailAddress
        field.tag = 0
        field.returnKeyType = .next
        field.delegate = self
        return field
    }()
    
    lazy var usernameField: UATextField = {
        let icon = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        icon.image = UIImage(systemName: "person")
        
        let field = UATextField()
        field.leftView = icon
        field.leftViewMode = .always
        field.placeholder = "Username"
        field.autocapitalizationType = .none
        // field.textContentType = .username
        field.autocorrectionType = .no
        field.tag = 1
        field.returnKeyType = .next
        field.delegate = self
        return field
    }()
    lazy var toggleVisibilityButton: IconButton = {
        let button = IconButton(image: UIImage(systemName: "eye.slash.fill"),
                                activeImageColor: .red,
                                size: CGSize(width: 24, height: 24),
                                target: self, action: #selector(togglePasswordVisibility(sender:)))
        button.selectedImage = UIImage(systemName: "eye.fill")
        return button
    }()
    lazy var passwordField: UATextField = {
        let icon = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        icon.image = UIImage(systemName: "lock")
        
        let field = UATextField()
        field.leftView = icon
        field.leftViewMode = .always
        field.placeholder = "Password"
        field.autocapitalizationType = .none
        field.textContentType = viewModel.isNewUser ? .newPassword : .password
        field.isSecureTextEntry = true
        field.autocorrectionType = .no
        field.tag = viewModel.isNewUser ? 2 : 1
        field.returnKeyType = .go
        field.delegate = self
        field.rightView = toggleVisibilityButton
        field.rightViewMode = .always
        return field
    }()

    lazy var agreeToTermsText: UITextView = {
        let textView = UITextView()
        let prependText = "By signing up, I agree to the "
        let tosLinkText = "Terms of Service"
        let firstJoiner = " and "
        let privacyPolicyLinkText = "Privacy Policy"
        let secondJoiner = ", including "
        let cookieUseLinkText = "Cookie Use"
        let appendText = "."
        let attributedString = NSMutableAttributedString(string: "\(prependText)\(tosLinkText)\(firstJoiner)\(privacyPolicyLinkText)\(secondJoiner)\(cookieUseLinkText)\(appendText)")
        
        // Set the 'click here' substring to be the link
        var nextURLIndex = prependText.count
        attributedString.setAttributes([.link: Config.tosURL],
                                       range: NSRange(location: nextURLIndex, length: tosLinkText.count))
        nextURLIndex += tosLinkText.count + firstJoiner.count
        attributedString.setAttributes([.link: Config.privacyURL],
                                       range: NSRange(location: nextURLIndex, length: privacyPolicyLinkText.count))
        nextURLIndex += privacyPolicyLinkText.count + secondJoiner.count
        attributedString.setAttributes([.link: Config.cookieUseURL],
                                       range: NSRange(location: nextURLIndex, length: cookieUseLinkText.count))
        nextURLIndex += cookieUseLinkText.count + appendText.count
        
        var style = NSMutableParagraphStyle()
        style.lineSpacing = 8
        
        attributedString.addAttributes([
            .font: TypographyStyle.body.font,
            .foregroundColor: UIColor.customTextColor,
            .paragraphStyle: style,
            .backgroundColor: UIColor.backgroundMain
        ], range: NSRange(location: 0, length: nextURLIndex))
        
        textView.attributedText = attributedString
        textView.isUserInteractionEnabled = true
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.delegate = self
        textView.backgroundColor = UIColor.backgroundMain
        
        textView.translatesAutoresizingMaskIntoConstraints = true
        // Set how links should appear
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.systemBlue
        ]
        return textView
    }()

    lazy var submitButton = UAButton(type: .normal, title: "Submit", target: self, action: #selector(submit(_:)))
    lazy var errorView = ErrorView()
    lazy var resetPasswordButton = UAButton(type: .link,
                                            title: "I forgot my password",
                                            target: self, action: #selector(resetPassword(_:)))

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [emailField])
        
        if viewModel.isNewUser {
            stackView.addArrangedSubview(usernameField)
        }
        stackView.addArrangedSubview(passwordField)
        stackView.addArrangedSubview(errorView)
        
        if viewModel.isNewUser {
            stackView.addArrangedSubview(agreeToTermsText)
        }
        stackView.addArrangedSubview(submitButton)
        if !viewModel.isNewUser {
            stackView.addArrangedSubview(resetPasswordButton)
        }
        
        stackView.layoutMargins = StyleConstants.defaultMarginInsets
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        return scrollView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = viewModel.isNewUser ? "Register" : "Login"
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(scrollView)
        scrollView.fill(view: self.view)
        
        viewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self.submitButton.showLoading()
                } else {
                    self.submitButton.hideLoading()
                }
            }
        }
        viewModel.didSetErrorMessage = { message in
            guard message != nil else { return }
            DispatchQueue.main.async {
                self.errorView.errorMessage = message
            }
        }

        agreeToTermsText.sizeToFit()
        hideKeyboardWhenTappedAround()
        scrollView.scrollViewAvoidKeyboard()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize.height = stackView.bounds.size.height
    }
    @objc func submit(_ sender: Any) {
        viewModel.submit(username: usernameField.text, email: emailField.text, password: passwordField.text)
    }
    @objc func resetPassword(_: Any) {
        navigationController?.pushViewController(ForgotPasswordViewController(mainCoordinator: mainCoordinator),
                                                 animated: true)
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
}
extension AuthViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       // Try to find next responder
        
        switch textField.returnKeyType {
        case .next:
            if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
               nextField.becomeFirstResponder()
            } else {
               // Not found, so remove keyboard.
               textField.resignFirstResponder()
            }
        case .go:
            submit(textField)
        default:
            textField.resignFirstResponder()
        }
       
       // Do not add a line break
       return false
    }
}
extension AuthViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        var allowedHosts: [String] = ["github.com", "urbanapplause.com"]
        #if DEBUG
        allowedHosts.append(contentsOf: ["ngrok.com", "localhost"])
        #endif
        
        if let domain = URL.host, allowedHosts.contains(domain) {
            let vc = SFSafariViewController(url: URL, configuration: SFSafariViewController.Configuration())
            vc.delegate = self
            present(vc, animated: true, completion: nil)
        }
        return false
    }
}

extension AuthViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    }
}
