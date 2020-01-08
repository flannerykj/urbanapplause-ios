//
//  TabBarController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import BSImagePicker
import Photos
import MapKit

class TabBarController: UITabBarController {
    var store: Store
    var appContext: AppContext
    let dhTabBar = UATabBar()
    var selectedPlacemark: CLPlacemark?
    
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
    lazy var mapTab = UINavigationController(rootViewController: mapRootVC)
    let mapTabBarItem = UITabBarItem(title: "Map",
                                     image: UIImage(systemName: "map"),
                                     selectedImage: UIImage(systemName: "map.fill"))
    
    lazy var listRootVC = SearchPostsViewController(appContext: appContext)
    lazy var listTab = UINavigationController(rootViewController: listRootVC)
    lazy var listTabBarItem = UITabBarItem(title: "Search",
                                           image: UIImage(systemName: "magnifyingglass"),
                                           selectedImage: UIImage(systemName: "magnifyingglass"))
    
    lazy var collectionsRootVC = GalleriesViewController(userId: store.user.data?.id,
                                                           appContext: appContext)
    lazy var collectionsTab = UINavigationController(rootViewController: collectionsRootVC)
    let collectionsTabBarItem = UITabBarItem(title: "Galleries",
                                             image: UIImage(systemName: "square.grid.2x2"),
                                             selectedImage: UIImage(systemName: "square.grid.2x2.fill"))

    // lazy var addTab = NewPostViewController(appContext: self.appContext)
    // let addTabBarItem = UITabBarItem(title: nil, image: nil, selectedImage: nil) // placeholder
    
    lazy var profileTab: UINavigationController? = {
        guard let user = store.user.data else { return nil }
        let profileRootVC = ProfileViewController(user: user, appContext: appContext)
        let nav = UINavigationController(rootViewController: profileRootVC)
        return nav
    }()
    let profileTabBarItem = UITabBarItem(title: "Profile",
                                         image: UIImage(systemName: "person"),
                                         selectedImage: UIImage(systemName: "person.fill"))
    
    lazy var settingsRootVC = SettingsViewController(store: store, appContext: appContext)
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
        
        if self.appContext.authService.isAuthenticated {
            controllers.append(collectionsTab)
            
            if let profileTab = profileTab {
                controllers.append(profileTab)
            }
        }
        controllers.append(settingsTab)
        
        self.viewControllers = controllers
        dhTabBar.middleButton.addTarget(self, action: #selector(createNewPressed(_:)), for: .touchUpInside)
    }
    
    public func pickImageForNewPost(placemark: CLPlacemark? = nil) {
        self.selectedPlacemark = placemark
        if appContext.authService.isAuthenticated {
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let takePhotoAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
                let cameraController = CameraViewController(appContext: self.appContext)
                cameraController.delegate = self
                cameraController.modalPresentationStyle = .fullScreen
                cameraController.popoverPresentationController?.sourceView = self.view
                cameraController.popoverPresentationController?.sourceRect = self.view.frame
                self.present(cameraController, animated: true, completion: nil)
            })
            let pickPhotoAction = UIAlertAction(title: "Photo Library",
                                                style: .default, handler: { _ in
                                                    
                let controller = BSImagePickerViewController()
                controller.maxNumberOfSelections = 1
                self.bs_presentImagePickerController(controller, animated: true,
                                                     select: { (asset) -> Void in
                                                        self.handleSelectedAsset(asset, controller: controller)
                }, deselect: { (_) -> Void in
                    // User deselected an assets.
                    // Do something, cancel upload?
                }, cancel: { (_) -> Void in
                    // User cancelled. And this where the assets currently selected.
                }, finish: { (_) -> Void in
                    // self.photos = assets + self.photos
                }, completion: nil)
            })
            alertController.addAction(takePhotoAction)
            alertController.addAction(pickPhotoAction)
            alertController.addAction(cancelAction)
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = self.view.frame
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            self.showAlertForLoginRequired(desiredAction: "post",
                                           appContext: self.appContext)
        }
    }
    
    private func handleSelectedAsset(_ asset: PHAsset, controller: BSImagePickerViewController) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.progressHandler = { progress, error, stop, info in
            DispatchQueue.main.async {
                // self.progressBar.progress = Float(progress)
                // self.progressBar.isHidden = false
            }
        }
        let cachingManager = PHCachingImageManager()
        cachingManager.requestImageDataAndOrientation(for: asset,
                                                      options: requestOptions,
                                                      resultHandler: { data, typeIdentifier, orientation, _ in
                                                        
                                                        DispatchQueue.main.async {
                                                            controller.dismiss(animated: true, completion: nil)
                                                            log.debug("mimetype: \(typeIdentifier)")
                                                            // self.progressBar.isHidden = true
                                                            if let imgData = data {
                                                                self.createNewPost(withImageData: imgData)
                                                            } else {
                                                                log.error("could not get image data")
                                                            }
                                                        }
        })
    }
    
    @objc func createNewPressed(_: Any) {
        pickImageForNewPost()
    }
    
    private func createNewPost(withImageData imageData: Data) {
        let controller = NewPostViewController(imageData: imageData, placemark: self.selectedPlacemark, appContext: self.appContext)
        controller.delegate = self
        let nav = UINavigationController(rootViewController: controller)
        // prevent swipe to dismiss so we can check for unsaved changes in didAttemptToDismiss.
        nav.isModalInPresentation = true
        nav.presentationController?.delegate = self
        self.present(nav, animated: true, completion: nil)
    }
    
}
extension TabBarController: CameraViewDelegate {
    func cameraController(_ controller: CameraViewController, didFinishWithImage: UIImage?, data: Data?, atLocation location: CLLocation?) {
        guard let imageData = data else {
            log.error("Camera returned no data")
            return
        }
        if selectedPlacemark == nil, let loc = location {
            selectedPlacemark = MKPlacemark(coordinate: loc.coordinate) as CLPlacemark
        }
        controller.dismiss(animated: true, completion: {
            self.createNewPost(withImageData: imageData)
        })
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
        // wait for upload images to complete
    }
    
    func didCompleteUploadingImages(post: Post) {
        self.listRootVC.didDeletePost(post: post)
        self.mapRootVC.didCompleteUploadingImages(post: post)
    }
    
    func didDeletePost(post: Post) {
        self.listRootVC.didCompleteUploadingImages(post: post)
        self.mapRootVC.didDeletePost(post: post)
    }
}
