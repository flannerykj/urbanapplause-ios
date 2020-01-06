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


@objc(ShareViewController2)
class ShareViewController2: UIViewController {
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
    
    var configurationItems: [SLComposeSheetConfigurationItem] {
        return [locationConfigurationItem]
    }
    
    var selectedImageData: Data?
    var imagePlacemark: CLPlacemark?
    var imageDate: Date?
    
    func isContentValid() -> Bool {
        guard self.authService.isAuthenticated else { self.handleError(AuthError.notAuthenicated, isFatal: true); return false }
        if selectedImageData != nil, imagePlacemark != nil {
            return true
        }
        return false
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.systemGray6
        tableView.contentInset = UIEdgeInsets(top: 50, left: 24, bottom: 50, right: 24)
        tableView.layer.cornerRadius = 8
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
        tableView.topAnchor.constraint(equalTo: view.topAnchor),
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        setImageFromExtensionContext()
    }
    
    func didSelectPost() {
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
extension ShareViewController2: URLSessionDelegate {
    
}
extension ShareViewController2: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return configurationItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.configurationItems[indexPath.row]
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.value
        return cell
    }
    
    
    
}
