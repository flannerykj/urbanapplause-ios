//
//  TabBarController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {
    var store: Store
    var mainCoordinator: MainCoordinator
    
    init(store: Store, mainCoordinator: MainCoordinator) {
        self.store = store
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var mapRootVC = PostMapViewController(viewModel: PostMapViewModel(mainCoordinator: mainCoordinator),
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
    
    lazy var collectionsRootVC = CollectionsViewController(userId: store.user.data!.id,
                                                           mainCoordinator: mainCoordinator)
    lazy var collectionsTab = UINavigationController(rootViewController: collectionsRootVC)
    let collectionsTabBarItem = UITabBarItem(title: "Galleries",
                                             image: UIImage(systemName: "square.grid.2x2"),
                                             selectedImage: UIImage(systemName: "square.grid.2x2.fill"))
    
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

        mapTab.tabBarItem = mapTabBarItem
        listTab.tabBarItem = listTabBarItem
        collectionsTab.tabBarItem = collectionsTabBarItem
        profileTab?.tabBarItem = profileTabBarItem
        settingsTab.tabBarItem = settingsTabBarItem

        var controllers = [
            mapTab,
            listTab,
            collectionsTab
        ]
        
        if let profile = profileTab {
            controllers.append(profile)
        }
        controllers.append(settingsTab)
        self.viewControllers = controllers
    }
}
