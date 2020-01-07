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
import UrbanApplauseShared

let log = DHLogger.self

@objc(ShareViewController)
class ShareViewController: SLComposeServiceViewController {
    let keychainService = KeychainService()
    lazy var authService = AuthService(keychainService: keychainService)
    lazy var apiService = APIService(keychainService: keychainService)
    let appURLScheme = "urbanapplause"

    lazy var locationConfigurationItem: SLComposeSheetConfigurationItem = {
       let item = SLComposeSheetConfigurationItem()!
        item.title = "Location"
        item.tapHandler = self.editConfigurationItemTapped
        return item
    }()
    
    lazy var dateConfigurationItem: SLComposeSheetConfigurationItem = {
       let item = SLComposeSheetConfigurationItem()!
        item.title = "Date"
        item.tapHandler = self.editConfigurationItemTapped
        return item
    }()
    func editConfigurationItemTapped() {
        print("tapped")
    }
    
    var selectedImageData: Data?
    var imagePlacemark: CLPlacemark?
    var imageDate: Date?
    
    override func isContentValid() -> Bool {
        guard self.authService.isAuthenticated else { self.handleError(AuthError.notAuthenicated, isFatal: true); return false }
        if selectedImageData != nil, imagePlacemark != nil {
            return true
        }
        return false
    }
    
    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return [locationConfigurationItem]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setImageFromExtensionContext()
    }
    
    override func didSelectPost() {
        guard let imageData = self.selectedImageData else { return }
        apiService.shareImage(imageData,
                              withMetaData: [:],
                              onCreatePost: {
                                DispatchQueue.main.async {
                                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                                }
        },
                              imageUploadDelegate: self,
                              onError: { error in
                                DispatchQueue.main.async {
                                    self.handleError(error)
                                }
        })
        
    }
    
    func setImageFromExtensionContext() {
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        let contentType = kUTTypeImage as String
        guard let attachments = content.attachments else {
            self.handleError(AttachmentError.noneProvided)
            return
        }
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(contentType) {
                attachment.loadItem(forTypeIdentifier: contentType, options: nil) { data, error in
                    if let error = error {
                        self.handleError(AttachmentError.unableToLoad(error))
                    } else {
                        let url = data as! NSURL
                        if let imageSource = CGImageSourceCreateWithURL(url, nil) {
                            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?
                            if let exifDict = imageProperties as? [String: Any] {
                                print("exifDict: \(exifDict)")
                                if let placemark = ImageService.getPlacemarkFromExif(exifDict),
                                    let location = placemark.location {
                                    self.locationConfigurationItem.value = location.description
                                    CLGeocoder().reverseGeocodeLocation(location, completionHandler: { placemarks, error in
                                        if error == nil, let placemark = placemarks?.first {
                                            // TODO - move placemark title extension to shared
                                            self.locationConfigurationItem.value = placemark.description
                                        }
                                    })

                                } else {
                                    log.debug("could not get placemark")
                                }

                            }
                        }
                        
                        do {
                            self.selectedImageData = try Data(contentsOf: url as URL)
                        } catch {
                            log.error(error)
                            self.handleError(AttachmentError.unableToLoad(error))
                        }
                    }
                }
            }
        }
    }
    
    func handleError(_ error: UAError, isFatal: Bool = false) {
        log.error(error)
        let alert = UIAlertController(title: "Error", message: error.userMessage, preferredStyle: .alert)
            
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
            if isFatal {
                self.extensionContext?.cancelRequest(withError: error)
            }
        }
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
}
extension ShareViewController: URLSessionDelegate {
    
}
