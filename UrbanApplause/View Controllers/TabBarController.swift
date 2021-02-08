//
//  TabBarController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Photos
import MapKit
import Shared

class TabBarController: UITabBarController {
    var store: Store
    var appContext: AppContext
    let uaTabBar = UATabBar()
    var selectedPlacemark: CLPlacemark?
    var imagePicker: UAImagePicker!
    
    init(store: Store, appContext: AppContext) {
        self.store = store
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var mapRootVC = PostMapViewController2(viewModel: PostMapViewModel2(appContext: appContext),
                                               appContext: appContext)
    lazy var mapTab = UANavigationController(rootViewController: mapRootVC)
    let mapTabBarItem = UITabBarItem(title: Strings.MapTabItemTitle,
                                     image: UIImage(systemName: "map"),
                                     selectedImage: UIImage(systemName: "map.fill"))
    
    lazy var searchRootVC = SearchPostsViewController(appContext: appContext)
    lazy var searchTab = UANavigationController(rootViewController: searchRootVC)
    lazy var searchTabBarItem = UITabBarItem(title: Strings.SearchTabItemTitle,
                                           image: UIImage(systemName: "magnifyingglass"),
                                           selectedImage: UIImage(systemName: "magnifyingglass"))
    
    lazy var collectionsRootVC = GalleriesViewController(userId: store.user.data?.id,
                                                           appContext: appContext)
    lazy var collectionsTab = UANavigationController(rootViewController: collectionsRootVC)
    let collectionsTabBarItem = UITabBarItem(title: Strings.GalleriesTabItemTitle,
                                             image: UIImage(systemName: "square.grid.2x2"),
                                             selectedImage: UIImage(systemName: "square.grid.2x2.fill"))

    // lazy var addTab = NewPostViewController(appContext: self.appContext)
    // let addTabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil) // placeholder
    
    lazy var profileTab: UANavigationController? = {
        guard let user = store.user.data else { return nil }
        let profileRootVC = ProfileViewController(user: user, appContext: appContext)
        let nav = UANavigationController(rootViewController: profileRootVC)
        return nav
    }()
    let profileTabBarItem = UITabBarItem(title: Strings.ProfileTabItemTitle,
                                         image: UIImage(systemName: "person"),
                                         selectedImage: UIImage(systemName: "person.fill"))
    
    lazy var settingsRootVC = SettingsViewController(store: store, appContext: appContext)
    lazy var settingsTab = UANavigationController(rootViewController: settingsRootVC)
    
    let settingsTabBarItem = UITabBarItem(title: Strings.SettingsTabItemTitle,
                                          image: UIImage(systemName: "gear"),
                                          selectedImage: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = UAImagePicker(presentationController: self, delegate: self)
        delegate = self
        uaTabBar.frame = self.tabBar.frame
        uaTabBar.delegate = self
        self.setValue(uaTabBar, forKey: "tabBar")
        
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
        
        if self.appContext.authService.isAuthenticated {
            controllers.append(collectionsTab)
            
            if let profileTab = profileTab {
                controllers.append(profileTab)
            }
        }
        controllers.append(settingsTab)
        
        self.viewControllers = controllers
        uaTabBar.middleButton.addTarget(self, action: #selector(createNewPressed(sender:)), for: .touchUpInside)
    }
    
    public func getImageForNewPost(sender: UIView, placemark: CLPlacemark? = nil) {
        self.selectedPlacemark = placemark
        if appContext.authService.isAuthenticated {
            self.imagePicker.showActionSheet(from: sender)
        } else {
            self.showAlertForLoginRequired(desiredAction: "post",
                                           appContext: self.appContext)
        }
    }

    @objc func createNewPressed(sender: UIView) {
        getImageForNewPost(sender: sender)
    }
    
    public func hideFloatingButton() {
        uaTabBar.middleButton.isHidden = true
    }
    
    public func showFloatingButton() {
        uaTabBar.middleButton.isHidden = false
    }

}

extension TabBarController: UITabBarControllerDelegate {
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        showFloatingButton()
        
        let indexOfSearchTab = 1
        if selectedIndex == indexOfSearchTab && item == searchTabBarItem {
            // search bar tab was double-tapped - focus the search bar
            _ = searchRootVC.searchController.searchBar.becomeFirstResponder()
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
        let didTapMiddleButton = sqrt((from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)) <= hitTestRadius
        return didTapMiddleButton && !middleButton.isHidden ?
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
extension TabBarController: CreatePostControllerDelegate {
    func createPostController(_ controller: CreatePostViewController, didDeletePost post: Post) {
        mapRootVC.createPostController(controller, didDeletePost: post)
        searchRootVC.createPostController(controller, didDeletePost: post)
    }
    
    func createPostController(_ controller: CreatePostViewController, didCreatePost post: Post) {
        mapRootVC.createPostController(controller, didCreatePost: post)
        searchRootVC.createPostController(controller, didCreatePost: post)
    }
    
    func createPostController(_ controller: CreatePostViewController, didUploadImageData: Data, forPost post: Post) {
        mapRootVC.createPostController(controller, didUploadImageData: didUploadImageData, forPost: post)
        searchRootVC.createPostController(controller, didUploadImageData: didUploadImageData, forPost: post)
    }
    
    func createPostController(_ controller: CreatePostViewController, didBeginUploadForData: Data, forPost post: Post, job: NetworkServiceJob?) {
        mapRootVC.createPostController(controller, didBeginUploadForData: didBeginUploadForData, forPost: post, job: job)
        searchRootVC.createPostController(controller, didBeginUploadForData: didBeginUploadForData, forPost: post, job: job)
    }
}

extension TabBarController: UAImagePickerDelegate {
    func imagePickerDidCancel(pickerController: UIImagePickerController?) {
        pickerController?.dismiss(animated: true, completion: nil)
    }
    func imagePicker(pickerController: UIImagePickerController?, didSelectImage imageData: Data?, dataWithEXIF: Data?) {
        guard let data = imageData, let picker = pickerController else {
            return
        }
        createNewPost(pickerController: picker, withImageData: data, dataWithEXIF: dataWithEXIF)
    }
    private func createNewPost(pickerController: UIImagePickerController, withImageData imageData: Data, dataWithEXIF: Data?) {
        var imageEXIFService: ImageEXIFService?
        
        if let data = dataWithEXIF {
            imageEXIFService = ImageEXIFService(data: data)
        }
        let controller = CreatePostViewController(imageData: imageData,
                                                  imageEXIFService: imageEXIFService,
                                                  placemark: self.selectedPlacemark,
                                                  hideNavbarOnDisappear: true,
                                                  appContext: self.appContext)
        controller.delegate = self
//        let nav = UINavigationController(rootViewController: controller)
//        // prevent swipe to dismiss so we can check for unsaved changes in didAttemptToDismiss.
//        nav.isModalInPresentation = true
//        nav.presentationController?.delegate = self
        pickerController.pushViewController(controller, animated: true)
        // self.present(nav, animated: true, completion: nil)
    }
}
