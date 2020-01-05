//
//  TabBarController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import UrbanApplauseShared


class TabBarController: UITabBarController {
    var store: Store
    var mainCoordinator: MainCoordinator
    let dhTabBar = UATabBar()
    
    init(store: Store, mainCoordinator: MainCoordinator) {
        self.store = store
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var mapRootVC = PostMapViewController2(viewModel: PostMapViewModel2(mainCoordinator: mainCoordinator),
                                               mainCoordinator: mainCoordinator)
    lazy var mapTab = UINavigationController(rootViewController: mapRootVC)
    let mapTabBarItem = UITabBarItem(title: "Map",
                                     image: UIImage(systemName: "map"),
                                     selectedImage: UIImage(systemName: "map.fill"))
    
    lazy var listRootVC = SearchPostsViewController(mainCoordinator: mainCoordinator)
    lazy var listTab = UINavigationController(rootViewController: listRootVC)
    lazy var listTabBarItem = UITabBarItem(title: "Search",
                                           image: UIImage(systemName: "magnifyingglass"),
                                           selectedImage: UIImage(systemName: "magnifyingglass"))
    
    lazy var collectionsRootVC = GalleriesViewController(userId: store.user.data?.id,
                                                           mainCoordinator: mainCoordinator)
    lazy var collectionsTab = UINavigationController(rootViewController: collectionsRootVC)
    let collectionsTabBarItem = UITabBarItem(title: "Galleries",
                                             image: UIImage(systemName: "square.grid.2x2"),
                                             selectedImage: UIImage(systemName: "square.grid.2x2.fill"))

    // lazy var addTab = NewPostViewController(mainCoordinator: self.mainCoordinator)
    // let addTabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil) // placeholder
    
    lazy var profileTab: UINavigationController? = {
        guard let user = store.user.data else { return nil }
        let profileRootVC = ProfileViewController(user: user, mainCoordinator: mainCoordinator)
        let nav = UINavigationController(rootViewController: profileRootVC)
        return nav
    }()
    let profileTabBarItem = UITabBarItem(title: "Profile",
                                         image: UIImage(systemName: "person"),
                                         selectedImage: UIImage(systemName: "person.fill"))
    
    lazy var settingsRootVC = SettingsViewController(store: store, mainCoordinator: mainCoordinator)
    lazy var settingsTab = UINavigationController(rootViewController: settingsRootVC)
    
    let settingsTabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), selectedImage: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dhTabBar.frame = self.tabBar.frame
        dhTabBar.delegate = self
        self.setValue(dhTabBar, forKey: "tabBar")
        
        mapTab.tabBarItem = mapTabBarItem
        // listTab.tabBarItem = listTabBarItem
        collectionsTab.tabBarItem = collectionsTabBarItem
        // addTab.tabBarItem = addTabBarItem
        profileTab?.tabBarItem = profileTabBarItem
        settingsTab.tabBarItem = settingsTabBarItem

        var controllers = [
            mapTab,
            // listTab
        ]
        
        if self.mainCoordinator.authService.isAuthenticated {
            controllers.append(collectionsTab)
            
            if let profileTab = profileTab {
                controllers.append(profileTab)
            }
        }
        controllers.append(settingsTab)
        
        self.viewControllers = controllers
        dhTabBar.middleButton.addTarget(self, action: #selector(createNewPressed(_:)), for: .touchUpInside)
    }
    
    @objc func createNewPressed(_: Any) {
        if mainCoordinator.authService.isAuthenticated {
            let vc = NewPostViewController(mainCoordinator: self.mainCoordinator)
            vc.delegate = self
            let nav = UINavigationController(rootViewController: vc)
            // prevent swipe to dismiss so we can check for unsaved changes in didAttemptToDismiss.
            nav.isModalInPresentation = true
            nav.presentationController?.delegate = self
            self.present(nav, animated: true, completion: nil)
        } else {
            self.showAlertForLoginRequired(desiredAction: "post",
                                           mainCoordinator: self.mainCoordinator)
        }
    }
    
}
extension TabBarController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let indexOfSearchTab = 1
        if selectedIndex == indexOfSearchTab && item == listTabBarItem {
            // search bar tab was double-tapped - focus the search bar
            _ = listRootVC.searchController.searchBar.becomeFirstResponder()
        }
    }
}
class UATabBar: UITabBar {
    let diameter: CGFloat = 60

    lazy var middleButton = IconButton(image: UIImage(systemName: "camera"),
                                       imageColor: .white,
                                       backgroundColor: .systemPink,
                                       imageSize: CGSize(width: 30, height: 30))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMiddleButton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let overflow: CGFloat = 5
        if self.isHidden {
            return super.hitTest(point, with: event)
        }

        let from = point
        let to = middleButton.center
        let radius: CGFloat = diameter/2
        let hitTestRadius = radius + overflow
        return sqrt((from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)) <= hitTestRadius ?
            middleButton : super.hitTest(point, with: event)
    }

    func setupMiddleButton() {
        middleButton.heightConstraint.isActive = false
        middleButton.widthConstraint.isActive = false

        middleButton.translatesAutoresizingMaskIntoConstraints = true
        middleButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        middleButton.layer.shadowColor = UIColor.black.cgColor

        middleButton.defaultShadowRadius = 6
        middleButton.activeShadowRadius = 8

        middleButton.defaultShadowOpacity = 0.5
        middleButton.activeShadowOpacity = 0.6
        middleButton.frame.size = CGSize(width: diameter, height: diameter)

        /* middleButton.frame = CGRect(x: (UIScreen.main.bounds.width / 2) - (diameter / 2),
                                    y: 0,
                                    width: diameter,
                                    height: diameter) */
        // middleButton.frame.origin.y = 30
        middleButton.layer.cornerRadius = diameter/2
        //  middleButton.layer.masksToBounds = true
        let buttonMargin: CGFloat = 12
        let buttonOffset: CGFloat = (diameter / 2) + buttonMargin
        middleButton.center = CGPoint(x: UIScreen.main.bounds.width - buttonOffset, y: -buttonOffset)
        addSubview(middleButton)
    }
    
    
}
extension TabBarController: PostFormDelegate {
    func didCreatePost(post: Post) {
        self.listRootVC.didDeletePost(post: post)
        self.mapRootVC.didCreatePost(post: post)
    }
    
    func didDeletePost(post: Post) {
        self.listRootVC.didCreatePost(post: post)
        self.mapRootVC.didDeletePost(post: post)
    }
}
