//
//  ShareViewController2.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Social
import MobileCoreServices
import Photos
import UrbanApplauseShared
import Eureka

@objc(ShareNavigationController)
class ShareNavigationController: UIViewController {
    var keychainService = KeychainService()
    
    lazy var userID: Int? = {
        let authResponse: AuthResponse? = try? self.keychainService.load(itemAt: KeychainItem.tokens.userAccount)
        return authResponse?.user?.id
    }()
    lazy var networkService: NetworkService = {
        var headers: [String: String] = [:]
        do {
            let authTokens: AuthResponse =
                try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            headers["Authorization"] = "Bearer \(authTokens.access_token)"
        } catch {
            log.warning(error)
        }
        return NetworkService(customHeaders: headers, handleAuthError: { serverError in
           // self.endSession()
        })
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        let contentType = kUTTypeImage as String
        guard let attachments = content.attachments else {
            return
        }
        log.debug("attachements count: \(attachments.count)")

        if let attachment = attachments.first {
            log.debug("attachment: \(attachment)")
            if attachment.hasItemConformingToTypeIdentifier(contentType) {
                attachment.loadItem(forTypeIdentifier: contentType, options: nil) { data, error in
                    DispatchQueue.main.async {
                        log.debug("here")
                        if let error = error {
                            log.error(error)
                            // self.handleError(AttachmentError.unableToLoad(error))
                        } else {
                            log.debug("here2")
                            let url = data as! NSURL
                            log.debug("url: \(url)")
                            if let data = try? Data(contentsOf: url as URL) {
                                guard let userID = self.userID else {
                                    log.error("not logged in ")
                                    return
                                }
                                let controller = NewPostViewController(photos: [], imageData: data, networkService: self.networkService, userID: userID, fileCache: nil)
                                self.present(UINavigationController(rootViewController: controller), animated: true)
                                log.debug("pushed")
                                
                            } else {
                                log.error("couldnt read data")
                            }
                        }
                    }
                }
            } else {
                log.debug("invalid types")
            }
        }
   
    }
}
