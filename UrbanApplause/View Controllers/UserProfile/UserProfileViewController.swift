//
//  UserProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//
import UIKit

class ProfileViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var user: User
    
    var isAuthUser: Bool {
        if let userId = self.mainCoordinator.store.user.data?.id,
            userId == user.id {
            log.debug("user id: \(userId)")
            return true
        }
        return false
    }
    
    lazy var tabItems: [ToolbarTabItem] = {
        let userPostsViewModel = DynamicPostListViewModel(filterForPostedBy: user, filterForArtist: nil, filterForQuery: nil,
                                                   mainCoordinator: mainCoordinator)
        let userPostsVC = PostListViewController(viewModel: userPostsViewModel, mainCoordinator: mainCoordinator)

        let applaudedPostsViewModel = DynamicPostListViewModel(filterForUserApplause: user, mainCoordinator: mainCoordinator)
        let userApplauseVC = PostListViewController(viewModel: applaudedPostsViewModel,
                                                    mainCoordinator: mainCoordinator)
        
        return [
            ToolbarTabItem(title: "Posts", viewController: userPostsVC, delegate: self),
            ToolbarTabItem(title: "Applause", viewController: userApplauseVC, delegate: self)
        ]
    }()
    
    init(user: User, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    lazy var nameLabel: UILabel = UILabel(type: .h8)
    lazy var bioLabel: UILabel = UILabel(type: .body)
    lazy var memberSinceLabel: UILabel = UILabel(type: .body)
    
    let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshUserProfile(sender:)), for: .valueChanged)
        control.backgroundColor = UIColor.backgroundMain
        return control
    }()

    let profileIcon = UIImageView(image: UIImage(systemName: "person.fill"))

    lazy var headerTextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, bioLabel, memberSinceLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()
    
    lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileIcon, headerTextStackView])
        profileIcon.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            profileIcon.widthAnchor.constraint(equalToConstant: 55),
            profileIcon.heightAnchor.constraint(equalTo: profileIcon.widthAnchor)
        ])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .top
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = StyleConstants.contentMargin
        return stackView
    }()
    
    lazy var tabsViewController = TabbedToolbarViewController(headerContent: headerStackView,
                                                              tabItems: self.tabItems,
                                                              mainCoordinator: mainCoordinator)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundMain
        navigationItem.title = isAuthUser ? "My Profile" : self.user.username
        if isAuthUser {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit,
                                             target: self, action: #selector(pressedEdit(_:)))
            navigationItem.rightBarButtonItem = editButton
        }
        view.addSubview(tabsViewController.view!)
        tabsViewController.view!.fill(view: view)
        addChild(tabsViewController)
        tabsViewController.didMove(toParent: self)
        updateLabels()
    }
    
    @objc func refreshUserProfile(sender: UIRefreshControl) {
        let endpoint = PrivateRouter.getUser(id: user.id)
        _ = mainCoordinator.networkService.request(endpoint) { (result: UAResult<UserContainer>) in
            
            DispatchQueue.main.async {
                sender.endRefreshing()
                switch result {
                case .success(let userContainer):
                    if self.isAuthUser {
                        self.mainCoordinator.store.user.data = userContainer.user
                    }
                    self.user = userContainer.user
                    self.updateLabels()
                case .failure(let error):
                    log.error(error)
                }
            }
        }
    }
    
    func updateLabels() {
        nameLabel.text = user.username
        if let bio = user.bio, bio.count > 0 {
            bioLabel.isHidden = false
            bioLabel.text = bio
            bioLabel.font = TypographyStyle.body.font
        } else {
            bioLabel.isHidden = !isAuthUser
            bioLabel.text = "No bio added"
            bioLabel.font = TypographyStyle.placeholder.font
        }
        if let dateString = user.createdAt?.justTheDate {
            memberSinceLabel.text = "Member since \(dateString)"
        }
    }
   
    @objc func pressedEdit(_ sender: UIBarButtonItem) {
        let vc = EditProfileViewController(mainCoordinator: mainCoordinator)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ProfileViewController: EditProfileDelegate {
    func didUpdateUser(_ user: User) {
        self.user = user
        self.updateLabels()
    }
}
extension ProfileViewController: ToolbarTabItemDelegate {
    
}
