//
//  NewPostViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Eureka
import CoreLocation
import MapKit
import Photos
import ViewRow
import BSImagePicker
import UrbanApplauseShared

protocol PostFormDelegate: class {
    func didDeletePost(post: Post)
    func didCreatePost(post: Post)
}

class NewPostViewController: FormViewController, UINavigationControllerDelegate,
UIImagePickerControllerDelegate, UnsavedChangesController {
    private let spacesFileRepository = SpacesFileRepository()
    var post: Post?
    var hasUnsavedChanges: Bool = false
    var mainCoordinator: MainCoordinator
    var imagesData: [Data]
    weak var delegate: PostFormDelegate?
    var initialPlacemark: CLPlacemark?
    lazy var networkService = self.mainCoordinator.networkService
    var showMoreOptions: Bool = false {
        didSet {
            log.debug("did set showMoreOptions: \(showMoreOptions) ")
            if let toggleableSection = form.sectionBy(tag: "toggleable_fields") {
                if let buttonRow = form.rowBy(tag: "toggle_fields_button") as? ButtonRow {
                    buttonRow.title = showMoreOptions ? "Show fewer fields" : "Show more fields"
                    buttonRow.updateCell()
                }
                toggleableSection.hidden = Condition(booleanLiteral: !showMoreOptions)
                toggleableSection.evaluateHidden()
            }
        }
    }
    var newPostState: NewPostState = .initial {
        didSet {
            DispatchQueue.main.async {
                self.navigationItem.title = self.newPostState.title
                
                switch self.newPostState {
                case .initial:
                    self.navigationItem.rightBarButtonItem = self.saveButton
                default:
                    self.navigationItem.rightBarButtonItem = self.loaderButton
                }
            }
        }
    }
    var selectingArtistForIndex: Int = 0
    var editingPost: Post?
    var savedImages: [Int: UIImage] = [:]
    
    let progressBar: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        view.tintColor = .systemTeal
        view.backgroundColor = .systemGray
        view.progress = 0.5
        view.isHidden = true
        view.heightAnchor.constraint(equalToConstant: 10).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    init(placemark: CLPlacemark? = nil, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.initialPlacemark = placemark
        self.imagesData = []
        super.init(nibName: nil, bundle: nil)
        
        if let location = placemark?.location {
            CLGeocoder().reverseGeocodeLocation(location,
                                                completionHandler: { (placemarks, _) in
                                                    
                                                    if let placemarkWithInfo = placemarks?.first {
                                                        DispatchQueue.main.async {
                                                            if let locationRow = self.form.rowBy(tag: "location") as? LocationRow {
                                                                locationRow.value = placemarkWithInfo
                                                                locationRow.updateCell()
                                                                self.hasUnsavedChanges = false // this shouldn't count as an unsaved change
                                                            }
                                                        }
                                                    }
            })
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var loader = ActivityIndicator()
    lazy var loaderButton = UIBarButtonItem(customView: loader)
    
    lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                          target: self,
                                          action: #selector(pressedSubmit(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.lightGray
        loader.startAnimating()
        navigationItem.title = Copy.ScreenTitles.newPost
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = closeButton
        
        navigationItem.rightBarButtonItem = saveButton
        self.newPostState = .initial
        // self.tableView.separatorInset = .zero
        createForm()
    }
    
    func onUpdateForm() {
        let errors = form.validate()
        navigationItem.rightBarButtonItem?.isEnabled = errors.count == 0
    }
    
    lazy var selectedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    func createForm() {
        form +++ Section("Photos")
            <<< ButtonRow { row in
                row.tag = "add_photo_button"
                row.title = "Add a photo"
                row.onCellSelection { cell, _ in
                    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    let takePhotoAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
                        let cameraController = CameraViewController()
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
                                                                controller.dismiss(animated: true, completion: nil)
                                                                self.handleSelectedPhotos([asset])
                                                                // User selected an asset.
                                                                // Do something with it, start upload perhaps?
                                                                
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
                    alertController.popoverPresentationController?.sourceRect = cell.frame
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            <<< ViewRow<UIView> { (row) in
                row.tag = "photos"
                row.hidden = Condition(booleanLiteral: true)
            }
            .cellSetup { (cell, _) in
                cell.view = UIView(frame: CGRect(x: 0,
                                                 y: 0,
                                                 width: cell.contentView.frame.width,
                                                 height: 210))
                
                cell.view!.addSubview(self.selectedImageView)
                self.selectedImageView.fill(view: cell.view!)
                cell.view!.addSubview(self.progressBar)
                NSLayoutConstraint.activate([
                    self.progressBar.centerXAnchor.constraint(equalTo: cell.view!.centerXAnchor),
                    self.progressBar.centerYAnchor.constraint(equalTo: cell.view!.centerYAnchor),
                    self.progressBar.widthAnchor.constraint(equalTo: cell.view!.widthAnchor, multiplier: 0.8)
                ])
                cell.update()
            }
            
            +++ Section("Location")
            <<< LocationRow("location") { row in
                row.title = "Location"
                row.value = self.initialPlacemark
                row.onChange { _ in
                    self.hasUnsavedChanges = true
                }
            }
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Reorder, .Delete],
                                   header: "Artists",
                                   footer: "") {
                                    $0.tag = "artists"
                                    
                                    $0.addButtonProvider = { section in
                                        return ButtonRow {
                                            $0.tag = "add"
                                            $0.title = "Add an artist"
                                            
                                        }.cellUpdate { cell, _ in
                                            cell.textLabel?.textAlignment = .left
                                        }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        // this gets called IMMEDIATELY after the add button is pressed.
                                        // Doesn't actually wait for artist to be selected from following controller.
                                        let controller = ArtistSelectionViewController(mainCoordinator: self.mainCoordinator)
                                        controller.delegate = self
                                        
                                        self.selectingArtistForIndex = index
                                        self.navigationController?.pushViewController(controller, animated: true)
                                        return UAPushRow<Artist> {
                                            $0.tag = "artist_\(index)"
                                            $0.displayValueFor = {
                                                $0?.signing_name
                                            }
                                        }
                                    }
            }
            +++ Section()
            <<< ButtonRow {
                $0.tag = "toggle_fields_button"
                $0.title = "Show more fields"
                $0.onCellSelection { _, _ in
                    log.debug("show more")
                    self.showMoreOptions = !self.showMoreOptions
                }
            }
            +++ Section("") {
                $0.tag = "toggleable_fields"
                $0.hidden = Condition(booleanLiteral: !self.showMoreOptions)
            }
            <<< SwitchRow { row in
                row.tag = "active"
                row.value = true
                row.title = "This piece is still visible"
            }
            <<< SwitchRow { row in
                row.tag = "is_location_fixed"
                row.value = true
                row.title = "Location is fixed"
            }
            <<< PushRow<String> { row in
                row.tag = "surface_type"
                row.title = "Surface type"
                row.options = ["Wall", "Billboard", "Street sign", "Train", "Truck or car", "Sidewalk" /*, "Other" */]
                // row.value = "Wall"
            }
            
            <<< DateRow { row in
                row.tag = "recordedAt"
                row.title = "Photographed on"
                row.value = Date()
            }
            +++ Section()
    }
    
    func fillFormFromExifData(properties: [String: Any]) {
        if let dateRow = self.form.rowBy(tag: "recordedAt") as? DateRow,
            let date = ImageService.getDateFromExif(properties) {
            dateRow.value = date
            dateRow.updateCell()
        }
        if let locationRow = self.form.rowBy(tag: "location") as? LocationRow,
            let placemark = ImageService.getPlacemarkFromExif(properties) {
            
            guard let location = placemark.location else { return }
            
            CLGeocoder().reverseGeocodeLocation(location,
                                                completionHandler: { (placemarks, _) in
                                                    if let placemarkWithInfo = placemarks?.first {
                                                        DispatchQueue.main.async {
                                                            locationRow.value = placemarkWithInfo
                                                            locationRow.updateCell()
                                                        }
                                                    }
            })
            locationRow.value = placemark
            locationRow.updateCell()
        }
    }
    func setPhotosFromData(_ imagesData: [Data]) {
        self.hasUnsavedChanges = true
        self.imagesData = imagesData
        if let photoButtonRow = self.form.rowBy(tag: "add_photo_button") {
            photoButtonRow.title = imagesData.count > 0 ? "Use a different photo" : "Add a photo"
        }
        if let photosRow = self.form.rowBy(tag: "photos") as? ViewRow, let data = self.imagesData.first {
            photosRow.hidden = false
            photosRow.evaluateHidden()
            self.selectedImageView.image = UIImage(data: data)
            photosRow.updateCell()
        }
    }
    func handleSelectedPhotos(_ photos: [PHAsset]) {
        selectedImageView.image = nil
        self.imagesData = [] // clear existing  photos.
        var errors = [Error]()
        var newImageData = [Data]()
        let cachingManager = PHCachingImageManager()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.progressHandler = { progress, error, stop, info in
            DispatchQueue.main.async {
                self.progressBar.progress = Float(progress)
                self.progressBar.isHidden = false
            }
        }
        for photo in photos {
            DispatchQueue.global(qos: .userInitiated).async {
                cachingManager.requestImageDataAndOrientation(for: photo,
                                                              options: requestOptions,
                                                              resultHandler: { data, typeIdentifier, orientation, _ in
                                                                
                                                                DispatchQueue.main.async {
                                                                    log.debug("mimetype: \(typeIdentifier)")
                                                                    self.progressBar.isHidden = true
                                                                    if let imgData = data {
                                                                        if let type = typeIdentifier,
                                                                            type == "public.heic" {
                                                                            
                                                                            let image = UIImage(data: imgData)
                                                                            if let jpegData = image?.jpegData(compressionQuality: 0.7) {
                                                                                newImageData.append(jpegData)
                                                                            }
                                                                        } else {
                                                                            newImageData.append(imgData)
                                                                        }
                                                                    } else {
                                                                        log.error("could not get image data")
                                                                        errors.append(PHAssetError.failedToGetData(typeIdentifier))
                                                                    }
                                                                    if newImageData.count + errors.count == photos.count {
                                                                        self.setPhotosFromData(newImageData)
                                                                    }
                                                                }
                                                                
                })
                photo.requestContentEditingInput(with: nil, completionHandler: { input, _ in
                    DispatchQueue.main.async {
                        if let uniformTypeIdentifier = input?.uniformTypeIdentifier {
                            log.debug("type: \(uniformTypeIdentifier)")
                            if uniformTypeIdentifier == "public.heic" {
                                log.error("unsupported format")
                            }
                        }
                        if let url = input?.fullSizeImageURL, let fullImage = CIImage(contentsOf: url) {
                            let properties = fullImage.properties
                            self.fillFormFromExifData(properties: properties)
                        }
                    }
                })
            }
        }
    }
    
    func makeNewLocationBody(from placemark: CLPlacemark) -> [String: Any]? {
        var body = Parameters()
        guard let coords = placemark.location?.coordinate else { return nil }
        body = [
            "coordinates": [
                "latitude": coords.latitude,
                "longitude": coords.longitude
            ],
            "city": placemark.locality ?? "",
            "country": placemark.country ?? "",
            "street_address": placemark.name ?? "",
            "postal_code": placemark.postalCode ?? ""
        ]
        return body
    }
    
    @objc func pressedSubmit(_: Any) {
        let formValues = form.values()
        var payload: [String: Any] = [:]
        
        guard self.imagesData.count > 0 else {
            self.showAlert(message: "Please select a photo")
            return
        }
        guard let placemark = formValues["location"] as? CLPlacemark, let location = placemark.location else {
            self.showAlert(message: "Please select a location")
            return
        }
        guard let userId = mainCoordinator.store.user.data?.id else {
            log.error("no user id")
            return
        }
        if let description = formValues["description"] as? String {
            payload["description"] = description
        }
        payload["UserId"] = userId
        
        if let active = formValues["active"] as? Bool {
            payload["active"] = active
        }
        if let isLocationFixed = formValues["is_location_fixed"] as? Bool {
           payload["is_location_fixed"] = isLocationFixed
       }
        if let surfaceType = formValues["surface_type"] as? Bool {
            payload["surface_type"] = surfaceType
        }
        let artistKeys: [String] = formValues.keys.filter { $0.contains("artist") }
        var artists: [Artist] = []
        for artistKey in artistKeys {
            if let artist = formValues[artistKey] as? Artist {
                artists.append(artist)
            }
        }
        payload["artists"] = artists.map { String($0.id) }.joined(separator: ",")
        log.debug("payload: \(payload)")
        let geocoder = CLGeocoder()
        // Look up the location to get user-friendly location info from coords
        self.newPostState = .gettingLocationData
        geocoder.reverseGeocodeLocation(location,
                                        completionHandler: { (placemarks, error) in
                                            if error == nil {
                                                guard let firstPlacemark = placemarks?[0],
                                                    let locationBody = self.makeNewLocationBody(from: firstPlacemark) else { return }
                                                
                                                payload["location"] = locationBody
                                                self.savePost(body: payload)
                                            } else {
                                                self.newPostState = .initial
                                                self.showAlert(message: "Error occurred while reverse geocoding")
                                            }
        })
    }

    func savePost(body: Parameters) {
        self.newPostState = .savingPost
        // Create new Post and Post Images with filenames for uploaded images
        _ = networkService.request(PrivateRouter.createPost(values: body),
                                   completion: { (result: UAResult<PostContainer>) in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(let container):
                                            self.saveImages(post: container.post)
                                        case .failure(let error):
                                            self.newPostState = .initial
                                            self.showAlert(message: error.userMessage)
                                        }
                                    }
        })
    }
    
    func saveImages(post: Post) {
        self.newPostState = .uploadingImages
        guard let userID = self.mainCoordinator.store.user.data?.id else {
            log.error("no user")
            return
        }
        
        // Add new Post Images to Post
        let endpoint = PrivateRouter.uploadImages(postId: post.id, userId: userID, imagesData: self.imagesData)
        _ = networkService.request(endpoint, completion: { (result: UAResult<PostImagesContainer>) in
            DispatchQueue.main.async {
                self.newPostState = .initial
                switch result {
                case .success(let container):
                    post.PostImages = container.images
                    
                    // Backend won't have finished compressing images yet, so save on frontend to dispaly immediately
                    if self.imagesData.count == container.images.count { // images successfully saved matches what we have locally
                        for i in 0..<container.images.count {
                            let imageData = self.imagesData[i]
                            let file = container.images[i]
                            self.mainCoordinator.fileCache.addLocalData(imageData, for: file)
                            log.debug("file: \(file)")
                            if let thumbnail = file.thumbnail {
                                log.debug("thumbnail: \(thumbnail)")
                                self.mainCoordinator.fileCache.addLocalData(imageData, for: thumbnail)
                            }
                        }
                    }
                    self.delegate?.didCreatePost(post: post)
                    self.dismiss(animated: true, completion: nil)
                case .failure(let error):
                    self.showAlert(message: error.userMessage)
                }
            }
        })
    }
    @objc func cancel(_ sender: UIBarButtonItem) {
        self.confirmDiscardChanges()
    }
}

extension NewPostViewController: ArtistSelectionDelegate {
    func artistSelectionController(finishWithArtist artist: Artist?) {
        guard let artistsSection = self.form.sectionBy(tag: "artists") as? MultivaluedSection else {
            return
        }
        guard let selectedArtist = artist else {
            // remove the empty row that is automatically added as soon as user hits add button
            artistsSection.remove(at: self.selectingArtistForIndex)
            return
        }
        
        if let artistRow: UAPushRow<Artist> = artistsSection.rowBy(tag: "artist_\(self.selectingArtistForIndex)") {
            self.hasUnsavedChanges = true
            artistRow.value = selectedArtist
        }
    }
}

extension NewPostViewController: CameraViewDelegate {
    func cameraController(_ controller: CameraViewController, didFinishWithImage: UIImage?, data: Data?) {
        controller.dismiss(animated: true, completion: nil)
        guard let imageData = data else { log.error("no data"); return }
        let source: CGImageSource = CGImageSourceCreateWithData((imageData as! CFMutableData), nil)!
        let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [String: Any]
        self.fillFormFromExifData(properties: metadata)
        self.setPhotosFromData([imageData])
    }
}
