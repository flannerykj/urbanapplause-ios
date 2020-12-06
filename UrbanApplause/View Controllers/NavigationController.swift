//
//  NavigationController.swift
//  UrbanApplause
//
//  Created by Flann on 2020-12-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit


class UANavigationController: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
        hideFloatingButton()
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        if viewControllers.count == 2 {
            showFloatingButton()
        }
        return super.popViewController(animated: animated)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewControllers.count > 1 {
            hideFloatingButton()
        } else {
            showFloatingButton()
        }
    }
    
    
    private func hideFloatingButton() {
        if let tabController = self.tabBarController as? TabBarController {
            tabController.hideFloatingButton()
        }
    }
    
    private func showFloatingButton() {
        if let tabController = self.tabBarController as? TabBarController {
            tabController.showFloatingButton()
        }
    }
}
