//
//  ImagePicker.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Photos

private let log = DHLogger.self

public protocol ImagePickerDelegate: class {
    func imagePicker(pickerController: UIImagePickerController?, didSelectImage imageData: Data?, dataWithEXIF: Data?)
    func imagePickerDidCancel(pickerController: UIImagePickerController?)

}

open class ImagePicker: NSObject {
    
    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate
        
        self.pickerController.modalPresentationStyle = .custom
        self.pickerController.transitioningDelegate = self
        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false // remove square overlay showing crop guidlines
        self.pickerController.mediaTypes = ["public.image"]
    }
    public func showActionSheet(from sourceView: UIView) {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let action = UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
                alertController.dismiss(animated: true, completion: {
                    self?.onSelectCamera()
                })
            })
            alertController.addAction(action)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let action = UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
                alertController.dismiss(animated: true, completion: {
                    self?.onSelectPhotoLibrary()
                })
            })
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }
    
    private func onSelectCamera() {
        self.pickerController.sourceType = .camera
        self.presentationController?.present(self.pickerController, animated: true)
    }
    
    private func onSelectPhotoLibrary() {
        let onPermissionGranted = {
            self.pickerController.sourceType = .photoLibrary
            self.presentationController?.present(self.pickerController, animated: true)
        }
        
        let onPermissionsDenied = {
            self.presentationController?.showAlertForDeniedPermissions(permissionType: "photo library",
                                                                       handleOpenSettings: nil)
            self.delegate?.imagePicker(pickerController: nil, didSelectImage: nil, dataWithEXIF: nil)
        }
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        onPermissionGranted()
                    } else {
                        onPermissionsDenied()
                    }
                }
            })
        case .denied, .restricted:
            onPermissionsDenied()
        case .authorized:
            self.pickerController.sourceType = .photoLibrary
            self.presentationController?.present(self.pickerController, animated: true)
        case .limited:
            onPermissionGranted()
        @unknown default:
            self.delegate?.imagePicker(pickerController: nil, didSelectImage: nil, dataWithEXIF: nil)
        }
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {
    
    private func getDataWithEXIF(from info: [UIImagePickerController.InfoKey: Any], completion: @escaping (Data?) -> ()) {
        if let asset = info[.phAsset] as? PHAsset {
            // user selected a photo from library.
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true
            requestOptions.isNetworkAccessAllowed = true
            let cachingManager = PHCachingImageManager()
            cachingManager.requestImageDataAndOrientation(for: asset,
                                                          options: requestOptions,
                                                          resultHandler: { data, typeIdentifier, orientation, _ in
                                                            DispatchQueue.main.async {
                                                                if let imgData = data {
                                                                    completion(imgData)
                                                                } else {
                                                                    log.error("could not get image EXIF")
                                                                }
                                                            }
            })
        } else {
            // User did not grant access to Photo Library, therefore we do not have access to metadata
            completion(nil)
        }
    }
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.imagePickerDidCancel(pickerController: picker)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var selectedImage: UIImage?
        
         if let asset = info[.originalImage] as? UIImage {
            // User selected from image library
            selectedImage = asset
        } else {
            // User took a picture with camera
            guard let image = info[.editedImage] as? UIImage else {
                log.error("Camera returned no data")
                return
            }
            selectedImage = image
        }
        
        getDataWithEXIF(from: info, completion: { dataWithEXIF in
            self.delegate?.imagePicker(pickerController: picker,
                                       didSelectImage: selectedImage?.jpegData(compressionQuality: 0.7),
                                       dataWithEXIF: dataWithEXIF)
        })
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
extension ImagePicker: UIAdaptivePresentationControllerDelegate {
    
}
extension ImagePicker: UIViewControllerTransitioningDelegate {
    
}
