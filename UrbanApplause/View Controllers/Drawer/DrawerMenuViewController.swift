//
//  DrawerMenuViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

enum DrawerMenuItem: Int {
    case collections, profile, settings, help
}
protocol DrawerMenuDelegate: AnyObject {
    func didSelectMenuItem(_ menuItem: DrawerMenuItem)
}

class DrawerMenuViewController: UIViewController {
    weak var delegate: DrawerMenuDelegate?
    var mainCoordinator: MainCoordinator
    
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let spacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Main buttons
    lazy var profileButton = DrawerMenuButton(image: UIImage(systemName: "person"),
                                              title: "Profile", target: self,
                                              action: #selector(showProfile(_:)))
    
    lazy var collectionsButton = DrawerMenuButton(image: UIImage(systemName: "square.grid.2x2"),
                                                  title: "Galleries",
                                                  target: self,
                                                  action: #selector(showCollections(_:)))
    
    lazy var settingsButton = DrawerMenuButton(image: nil,
                                               title: "Settings",
                                               target: self,
                                               action: #selector(showSettings(_:)))
    
    lazy var helpButton = DrawerMenuButton(image: nil,
                                           title: "Help Center",
                                           target: self,
                                           action: #selector(showHelpCenter(_:)))
    
    lazy var logoutButton = DrawerMenuButton(image: nil,
                                             title: "Log out",
                                             target: self,
                                             action: #selector(logout(_:)))
    
    var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 2).isActive = true
        return view
    }()
    
    lazy var bottomStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            separatorLine,
            // settingsButton,
            helpButton,
            logoutButton
        ])
        stackView.accessibilityIdentifier = "drawerMenuStackView"
        stackView.spacing = 20
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            profileButton,
            collectionsButton,
            spacer,
            bottomStackView
        ])
        stackView.accessibilityIdentifier = "drawerMenuBottomStackView"
        stackView.layoutMargins = UIEdgeInsets(top: 40, left: 24, bottom: 24, right: 24)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 30
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var footerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "illo_leaves")
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        view.clipsToBounds = true
        
        view.addSubview(footerImageView)
        NSLayoutConstraint.activate([
            footerImageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            footerImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            footerImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(stackView)
        stackView.fill(view: self.view)
        
    }
    
    @objc func showCollections(_: Any) {
        delegate?.didSelectMenuItem(.collections)
    }
    @objc func showProfile(_: Any) {
        delegate?.didSelectMenuItem(.profile)
    }
    
    @objc func showSettings(_: Any) {
        delegate?.didSelectMenuItem(.settings)
    }
    @objc func showHelpCenter(_: Any) {
        delegate?.didSelectMenuItem(.help)
    }
    @objc func logout(_: Any) {
        mainCoordinator.logout(authContext: .userInitiated)
    }
}

class DrawerMenuButton: UIControl {
    
    lazy var imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: 0)

    var image: UIImage? {
        didSet {
           updateImage(image)
        }
    }
    
    lazy private var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor).isActive = true
        imageView.tintColor = .gray
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.baselineAdjustment = .none
        label.adjustsFontForContentSizeCategory = true
        if let font = UIFont(name: Helvetica.Default.rawValue, size: 18) {
            let fontMetrics = UIFontMetrics(forTextStyle: UIFont.TextStyle.title3)
            label.font = fontMetrics.scaledFont(for: font)
        }
        return label
    }()
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.accessibilityIdentifier = "smallMenuButtonStackView"
        stackView.isUserInteractionEnabled = false
        return stackView
    }()
    
    init(image: UIImage?, title: String, target: Any, action: Selector) {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.label.text = title
        addSubview(stackView)
        stackView.fill(view: self)
        self.addTarget(target, action: action, for: .touchUpInside)
        imageWidthConstraint.isActive = true
        updateImage(image)
    }
    
    func updateImage(_ image: UIImage?) {
        imageView.image = image?.withRenderingMode(.alwaysTemplate)
        if image != nil {
            imageWidthConstraint.constant = 20
        } else {
            imageWidthConstraint.constant = 0
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
