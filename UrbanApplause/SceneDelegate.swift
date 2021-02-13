//
//  SceneDelegate.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-09.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let appContext: AppContext = AppContext()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        appContext.delegate = self
        appContext.sharedApplication = UIApplication.shared
        #if DEBUG
        log.debug("debug")
        #else
        log.debug("release")
        #endif
        
        // UserDefaults.setBiometricPreference(preference: .none)
        // KeychainService().clear(itemAt: KeychainItem.credentials.userAccount)
        let rootViewController = LoadingViewController()
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        appContext.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {

        if let url = userActivity.webpageURL {
            log.info(url)
            
            var pathComponents = url.pathComponents
            if pathComponents.first == "/" { pathComponents.remove(at: 0)}
            
            // Check for valid reset password link
            if pathComponents.first == "update-password" {
                
                guard pathComponents.count == 2, let resetToken = pathComponents.last else {
                    log.error("update-password link is missing token path component")
                    return
                }
                guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let email = urlComponents.queryItems?.first(where: { item in
                          item.name == "email"
                      })?.value else {
                    log.error("update-password link contains no `email` query param`")
                    return
                }

                window?.rootViewController?.dismiss(animated: true, completion: {
                    let resetPasswordController = PasswordResetViewController(appContext: self.appContext, resetToken: resetToken, email: email)
                    resetPasswordController.delegate = self
                    self.window?.rootViewController?.present(UANavigationController(rootViewController: resetPasswordController), animated: true, completion: nil)
                })
                
            }
        }
    }
}

extension SceneDelegate: AppContextDelegate {
    func appContext(setRootController controller: UIViewController) {
        self.window?.rootViewController = controller
    }
}


extension SceneDelegate: PasswordResetViewControllerDelegate {
    func didResetPassword() {
        let alert = UIAlertController(title: "Success!", message: "Your password has been reset", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        })
        alert.addAction(action)
        window?.rootViewController?.present(alert, animated: true, completion: {
            // Present login controller.
        })
    }
}
