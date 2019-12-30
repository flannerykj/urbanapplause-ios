//
//  WelcomeViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-11.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class WelcomeViewController: UIViewController {
    var store: Store
    var mainCoordintor: MainCoordinator
    
    init(store: Store, mainCoordinator: MainCoordinator) {
        self.store = store
        self.mainCoordintor = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var welcomeLabel = UILabel(type: .h1, text: "Welcome to Urban Applause")
    lazy var introLabel = UILabel(type: .h8, text: Copy.Marketing.intro, alignment: .center)
    lazy var registerButton = UAButton(type: .primary,
                                       title: "Register",
                                       target: self,
                                       action: #selector(goToRegistration(_:)))
    lazy var loginButton = UAButton(type: .link, title: "Log in", target: self, action: #selector(goToLogin(_: )))

    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [welcomeLabel, introLabel, registerButton, loginButton])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.setCustomSpacing(36, after: introLabel)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidLoad() {
        welcomeLabel.numberOfLines = 0
        welcomeLabel.textAlignment = .center
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.layoutMarginsGuide.centerYAnchor),
            stackView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor)
        ])
    }
    
    @objc func goToLogin(_: Any) {
        navigationController?.pushViewController(AuthViewController(isNewUser: false,
                                                                    mainCoordinator: self.mainCoordintor),
                                                 animated: true)
    }
    @objc func goToRegistration(_: Any) {
        navigationController?.pushViewController(AuthViewController(isNewUser: true,
                                                                    mainCoordinator: self.mainCoordintor),
                                                 animated: true)
    }
}
