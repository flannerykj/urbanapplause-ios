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
import Shared

protocol CreatePostControllerDelegate: class {
    func didDeletePost(post: Post)
    func didCreatePost(post: Post)
    func didCompleteUploadingImages(post: Post)
}

private struct FormFieldKeys {
    static let photos = "photos"
    static let location = "location"
    static let addArtistButton = "add_artist_button"
    static let toggleFieldsButton = "toggle_fields_button"
    static let active = "active"
    static let locationFixed = "is_location_fixed"
    static let surfaceType = "surface_type"
    static func artistAtIndex(_ index: Int) -> String {
        return "artist_\(index)"
    }
    static let recordedAt = "recordedAt"
    static let description = "description"
}

private struct FormSectionKeys {
    static let artists = "artists"
    static let toggleableFields = "toggleable_fields"
}

class CreatePostViewController: FormViewController, UINavigationControllerDelegate,
UIImagePickerControllerDelegate, UnsavedChangesController {
    private var imageService: ImageEXIFService
    private let spacesFileRepository = SpacesFileRepository()
    var post: Post?
    var hasUnsavedChanges: Bool = false
    var appContext: AppContext
    var selectedImageData: Data
    weak var delegate: CreatePostControllerDelegate?
    var initialPlacemark: CLPlacemark?
    lazy var networkService = self.appContext.networkService
    var showMoreOptions: Bool = false {
        didSet {
            if let toggleableSection = form.sectionBy(tag: FormSectionKeys.toggleableFields) {
                if let buttonRow = form.rowBy(tag: FormFieldKeys.toggleFieldsButton) as? ButtonRow {
                    buttonRow.title = showMoreOptions ? Strings.ShowFewerFieldsButtonTitle : Strings.ShowMoreFieldsButtonTitle
                    buttonRow.updateCell()
                }
                toggleableSection.hidden = Condition(booleanLiteral: !showMoreOptions)
                toggleableSection.evaluateHidden()
            }
        }
    }
    var newPostState: NewPostState? {
        didSet {
            DispatchQueue.main.async {
                self.navigationItem.title = self.newPostState?.title
            }
        }
    }
    var selectingArtistForIndex: Int = 0
    var editingPost: Post?
    var savedImages: [Int: UIImage] = [:]
    
    var isLoading = false {
        didSet {
            DispatchQueue.main.async {
                if self.isLoading {
                    self.navigationItem.rightBarButtonItem = self.loaderButton
                } else {
                    self.navigationItem.rightBarButtonItem = self.saveButton
                }
            }
        }
    }
    
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
    
    init(imageData: Data, placemark: CLPlacemark? = nil, appContext: AppContext) {
        self.appContext = appContext
        self.initialPlacemark = placemark
        self.selectedImageData = imageData
        self.imageService = ImageEXIFService(data: imageData)
        super.init(nibName: nil, bundle: nil)
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
        navigationItem.title = Strings.NewPostScreenTitle
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .cancel,
                                          target: self,
                                          action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = closeButton
        
        navigationItem.rightBarButtonItem = saveButton
        self.newPostState = .initial
        // self.tableView.separatorInset = .zero
        selectedImageView.image = UIImage(data: selectedImageData)

        createForm()
    
        fillFormFromExifData()

        if let location = initialPlacemark?.location { // if user specified a location to use, overwrite anything pulled from image metadata. 
            CLGeocoder().reverseGeocodeLocation(location,
                                                completionHandler: { (placemarks, _) in
                                                    
                                                    if let placemarkWithInfo = placemarks?.first {
                                                        DispatchQueue.main.async {
                                                            if let locationRow = self.form.rowBy(tag: FormFieldKeys.location) as? LocationRow {
                                                                locationRow.value = placemarkWithInfo
                                                                locationRow.updateCell()
                                                                self.hasUnsavedChanges = false // this shouldn't count as an unsaved change
                                                            }
                                                        }
                                                    }
            })
        }
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
    
    private func createForm() {
        form +++ Section("Photos")
            <<< ViewRow<UIView> { (row) in
                row.tag = FormFieldKeys.photos
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
            
            +++ Section(Strings.LocationFieldLabel)
            <<< LocationRow { row in
                row.tag = FormFieldKeys.location
                row.title = Strings.LocationFieldLabel
                row.value = self.initialPlacemark
                row.onChange { _ in
                    self.hasUnsavedChanges = true
                }
            }
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Reorder, .Delete],
                                   header: Strings.ArtistsFieldLabel,
                                   footer: "") {
                                    $0.tag = FormSectionKeys.artists
                                    
                                    $0.addButtonProvider = { section in
                                        return ButtonRow {
                                            $0.tag = FormFieldKeys.addArtistButton
                                            $0.title = Strings.AddAnArtistButtonTitle
                                            
                                        }.cellUpdate { cell, _ in
                                            cell.textLabel?.textAlignment = .left
                                        }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        // this gets called IMMEDIATELY after the add button is pressed.
                                        // Doesn't actually wait for artist to be selected from following controller.
                                        let controller = ArtistSelectionViewController(appContext: self.appContext)
                                        controller.delegate = self
                                        self.selectingArtistForIndex = index
                                        self.present(UINavigationController(rootViewController: controller),
                                                     animated: true,
                                                     completion: nil)
                                        return UAPushRow<Artist> {
                                            $0.tag = FormFieldKeys.artistAtIndex(index)
                                            $0.displayValueFor = {
                                                $0?.signing_name
                                            }
                                        }
                                    }
            }
            +++ Section()
            <<< ButtonRow {
                $0.tag = FormFieldKeys.toggleFieldsButton
                $0.title = Strings.ShowMoreFieldsButtonTitle
                $0.onCellSelection { _, _ in
                    self.showMoreOptions = !self.showMoreOptions
                }
            }
            +++ Section {
                $0.tag = FormSectionKeys.toggleableFields
                $0.hidden = Condition(booleanLiteral: !self.showMoreOptions)
            }
            <<< SwitchRow { row in
                row.tag = FormFieldKeys.active
                row.value = true
                row.title = Strings.PostIsVisibleFieldLabel
            }
            <<< SwitchRow { row in
                row.tag = FormFieldKeys.locationFixed
                row.value = true
                row.title = Strings.LocationIsFixedFieldLabel
            }
            <<< PushRow<PostSurfaceType> { row in
                row.tag = FormFieldKeys.surfaceType
                row.title = Strings.SurfaceTypeFieldLabel
                row.options = PostSurfaceType.allCases
            }
            
            <<< DateRow { row in
                row.tag = FormFieldKeys.recordedAt
                row.title = Strings.PhotographedOnFieldLabel
                row.value = Date()
            }
            +++ Section()
    }
    
    func fillFormFromExifData() {
        if let dateRow = self.form.rowBy(tag: FormFieldKeys.recordedAt) as? DateRow,
            let date = imageService.dateFromExif {
            dateRow.value = date
            dateRow.updateCell()
        }
        if let locationRow = self.form.rowBy(tag: FormFieldKeys.location) as? LocationRow,
            let placemark = imageService.placemarkFromExif {
            
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
        
        guard let placemark = formValues[FormFieldKeys.location] as? CLPlacemark, let location = placemark.location else {
            self.showAlert(message: Strings.MissingLocationError)
            return
        }
        guard let userId = appContext.store.user.data?.id else {
            log.error("no user id")
            return
        }
        payload["UserId"] = userId
        
        if let active = formValues["active"] as? Bool {
            payload["active"] = active
        }
        if let isLocationFixed = formValues[FormFieldKeys.locationFixed] as? Bool {
           payload["is_location_fixed"] = isLocationFixed
       }
        if let surfaceType = formValues[FormFieldKeys.surfaceType] as? Bool {
            payload["surface_type"] = surfaceType
        }
        
        let artistKeys: [String] = formValues.keys.filter { $0.contains("artist") && !$0.contains("button") }
        var artists: [Artist] = []
        for artistKey in artistKeys {
            if let artist = formValues[artistKey] as? Artist {
                artists.append(artist)
            }
        }
        payload["artists"] = artists.map { String($0.id) }.joined(separator: ",")
        let geocoder = CLGeocoder()
        // Look up the location to get user-friendly location info from coords
        self.isLoading = true
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
                                                self.showAlert(message: Strings.LocationLookupError)
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
                                            self.delegate?.didCreatePost(post: container.post)
                                            self.saveImages(post: container.post)
                                        case .failure(let error):
                                            self.isLoading = false
                                            self.newPostState = .initial
                                            self.showAlert(message: error.userMessage)
                                        }
                                    }
        })
    }
    
    func saveImages(post: Post) {
        self.newPostState = .uploadingImages
        guard let userID = self.appContext.store.user.data?.id else {
            log.error("no user")
            return
        }
        
        // Add new Post Images to Post
        let endpoint = PrivateRouter.uploadImages(postId: post.id, userId: userID, imagesData: [selectedImageData])
        _ = networkService.request(endpoint, completion: { (result: UAResult<PostImagesContainer>) in
            DispatchQueue.main.async {
                self.isLoading = false
                self.newPostState = .initial
                switch result {
                case .success(let container):
                    post.PostImages = container.images
                    
                    // Backend won't have finished compressing images yet, so save on frontend to dispaly immediately
                    if let file = container.images.first {
                        self.appContext.fileCache.addLocalData(self.selectedImageData, for: file)
                        if let thumbnail = file.thumbnail {
                            self.appContext.fileCache.addLocalData(self.selectedImageData, for: thumbnail)
                        }
                    }
                    self.delegate?.didCompleteUploadingImages(post: post)
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

extension CreatePostViewController: ArtistSelectionDelegate {
    func artistSelectionController(_ controller: ArtistSelectionViewController, didSelectArtist artist: Artist?) {
        controller.dismiss(animated: true, completion: nil)
        guard let artistsSection = self.form.sectionBy(tag: FormSectionKeys.artists) as? MultivaluedSection else {
            return
        }
        guard let selectedArtist = artist else {
            // remove the empty row that is automatically added as soon as user hits add button
            artistsSection.remove(at: self.selectingArtistForIndex)
            return
        }
        
        if let artistRow: UAPushRow<Artist> = artistsSection.rowBy(tag: FormFieldKeys.artistAtIndex(selectingArtistForIndex)) {
            self.hasUnsavedChanges = true
            artistRow.value = selectedArtist
        }
    }
}
