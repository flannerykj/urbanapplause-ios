//
//  ShareViewController.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Photos

@objc(ShareViewController)
class ShareViewController: UIViewController {
    /*lazy var appContext = AppContext()
    var selectedImageData: Data?
    lazy var networkSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.urbanapplause.ios.BackgroundSession")
        config.sharedContainerIdentifier = Config.appGroupIdentifier
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        return session
    }()
    init() {
        super.init(nibName: nil, bundle: nil)
        if let authResponse: AuthResponse = try? appContext.keychainService.load(itemAt: KeychainItem.tokens.userAccount) {
            appContext.store.user.data = authResponse.user
        }
        appContext.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if appContext.authService.isAuthenticated {
            loadImageFromExtensionContext()
        } else {
            self.handleError(UAServerError(name: .AccessDeniedError), isFatal: true)
        }
    }
    
    func loadImageFromExtensionContext() {
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        let contentType = kUTTypeImage as String
            
        for attachment in (content.attachments ?? []) {
            if attachment.hasItemConformingToTypeIdentifier(contentType) {
                attachment.loadItem(forTypeIdentifier: contentType, options: nil) { data, error in
                    DispatchQueue.main.async {
                        if error == nil {
                            guard let url = data as? URL else {
                                self.handleError(ShareExtensionError.invalidURL)
                                return
                            }
                            if let imageData = try? Data(contentsOf: url) {
                                self.selectedImageData = imageData
                                let controller = NewPostViewController(imageData: imageData, appContext: self.appContext)
                                controller.delegate = self
                                let navController = UINavigationController(rootViewController: controller)
                                self.present(navController, animated: true, completion: nil)
                            } else {
                                self.handleError(ShareExtensionError.invalidData)
                            }
                        } else {
                            self.handleError(ShareExtensionError.attachmentLoadingError(error), isFatal: true)
                        }
                    }
                }
            } else {
                self.handleError(ShareExtensionError.invalidData, isFatal: true)
            }
        }
    }
    
    var extensionError: NSError {
        return NSError(domain: "com.urbanapplause.com.UrbanApplauseUpload", code: NSUserCancelledError, userInfo: nil)
    }
    
    func handleError(_ error: UAError, isFatal: Bool = false) {
        
        self.showAlert(title: "Error", message: error.userMessage, onDismiss: {
            if isFatal {
                self.extensionContext?.cancelRequest(withError: self.extensionError)
            }
        })
    }
    
}
extension ShareViewController: PostFormDelegate {

    func didCreatePost(post: Post) {
        // don't wait for image uploads to finish
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    func didCompleteUploadingImages(post: Post) {
        
    }
    
    func didDeletePost(post: Post) {}
}
extension ShareViewController: AppContextDelegate {
    func appContext(setRootController controller: UIViewController) {}
    func appContextOpenSettings(completion: @escaping (Bool) -> Void) {}
}
extension ShareViewController: URLSessionDelegate {
    */
}
