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
    func didSelect(imageData: Data?)
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

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
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

    private func pickerController(_ controller: UIImagePickerController, didSelect data: Data?) {
        controller.dismiss(animated: true, completion: nil)
        self.delegate?.didSelect(imageData: data)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
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
                                                                    self.pickerController(picker, didSelect: imgData)
                                                                } else {
                                                                    log.error("could not get image data")
                                                                }
                                                            }
            })
        } else {
            // user took a picture with camera
           guard let image = info[.originalImage] as? UIImage,
                let imageData = image.pngData() else {
                log.error("Camera returned no data")
                return
            }
            self.pickerController(picker, didSelect: imageData)
        }
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
