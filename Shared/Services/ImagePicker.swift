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
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self._showActionSheet(from: sourceView)
                    } else {
                        self.delegate?.imagePicker(pickerController: nil, didSelectImage: nil, dataWithEXIF: nil)
                    }
                }
            })
        case .denied, .restricted:
            self.presentationController?.showAlertForDeniedPermissions(permissionType: "photo library",
                                                                       handleOpenSettings: nil)
            self.delegate?.imagePicker(pickerController: nil, didSelectImage: nil, dataWithEXIF: nil)
            return
        case .authorized:
            _showActionSheet(from: sourceView)
        @unknown default:
            self.delegate?.imagePicker(pickerController: nil, didSelectImage: nil, dataWithEXIF: nil)
        }
    }

    private func _showActionSheet(from sourceView: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.createAction(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
//        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
//            alertController.addAction(action)
//        }
        if let action = self.createAction(for: .photoLibrary, title: "Photo library") {
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
    
    private func createAction(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
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
