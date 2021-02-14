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
    func createPostController(_ controller: CreatePostViewController,
                              didDeletePost post: Post)
    func createPostController(_ controller: CreatePostViewController,
                              didCreatePost post: Post)
    func createPostController(_ controller: CreatePostViewController,
                              didUploadImageData: Data,
                              forPost post: Post)
    func createPostController(_ controller: CreatePostViewController,
                              didBeginUploadForData: Data,
                              forPost post: Post,
                              job: NetworkServiceJob?)
}

private struct FormFieldKeys {
    static let photos = "photos"
    static let location = "location"
    static let addArtistButton = "add_artist_button"
    static let addArtistGroupButton = "add_artistGroup_button"
    static let toggleFieldsButton = "toggle_fields_button"
    static let active = "active"
    static let locationFixed = "is_location_fixed"
    static let surfaceType = "surface_type"
    static func artistAtIndex(_ index: Int) -> String {
        return "artist_\(index)"
    }
    static func artistGroupAtIndex(_ index: Int) -> String {
        return "artist_group_\(index)"
    }
    static let recordedAt = "recordedAt"
    static let description = "description"
}

private struct FormSectionKeys {
    static let artists = "artists"
    static let artistGroups = "artist_groups"
    static let toggleableFields = "toggleable_fields"
}

class CreatePostViewController: FormViewController, UINavigationControllerDelegate,
UIImagePickerControllerDelegate, UnsavedChangesController {
    private var hideNavbarOnDisappear: Bool // Set true if previous vc (i.e. UIImagePicker) requires navigationController's navbar to be hidden.
    private var imageService: ImageEXIFService?
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
    var selectingArtistForIndex: Int?
    var selectingArtistGroupForIndex: Int?
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
    
    init(imageData: Data, imageEXIFService: ImageEXIFService?, placemark: CLPlacemark? = nil, hideNavbarOnDisappear: Bool, appContext: AppContext) {
        self.appContext = appContext
        self.hideNavbarOnDisappear = hideNavbarOnDisappear
        self.initialPlacemark = placemark
        self.selectedImageData = imageData
        self.imageService = imageEXIFService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override var prefersStatusBarHidden: Bool {
        return false
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

        navigationItem.rightBarButtonItem = saveButton
        if navigationController == nil {
            let navigationBar = UINavigationBar()
            navigationBar.translatesAutoresizingMaskIntoConstraints = false
            
            navigationBar.barTintColor = UIColor.lightGray
            view.addSubview(navigationBar)
            NSLayoutConstraint.activate([
                navigationBar.rightAnchor.constraint(equalTo: view.rightAnchor),
                navigationBar.leftAnchor.constraint(equalTo: view.leftAnchor),
                navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                navigationBar.heightAnchor.constraint(equalToConstant: 50)
            ])
            navigationBar.items = [navigationItem]
        } else {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
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
            +++ Section()
            <<< TextRow { row in
                row.tag = "title"
                row.title = "Title"
                row.placeholder = "Optional"
                row.onChange { _ in
                    self.hasUnsavedChanges = true
                }
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
                                        if let nav = self.navigationController {
                                            nav.pushViewController(controller, animated: true)
                                        } else {
                                            self.present(UINavigationController(rootViewController: controller),
                                                         animated: true,
                                                         completion: nil)
                                        }
                                        return UAPushRow<Artist> {
                                            $0.tag = FormFieldKeys.artistAtIndex(index)
                                            $0.displayValueFor = {
                                                $0?.signing_name
                                            }
                                        }
                                    }
            }
            +++ MultivaluedSection(multivaluedOptions: [.Insert, .Reorder, .Delete],
                                   header: Strings.ArtistGroupsFieldLabel,
                                   footer: "") {
                                    $0.tag = FormSectionKeys.artistGroups
                                    
                                    $0.addButtonProvider = { section in
                                        return ButtonRow {
                                            $0.tag = FormFieldKeys.addArtistGroupButton
                                            $0.title = Strings.AddAnArtistGroupButtonTitle
                                            
                                        }.cellUpdate { cell, _ in
                                            cell.textLabel?.textAlignment = .left
                                        }
                                    }
                                    $0.multivaluedRowToInsertAt = { index in
                                        // this gets called IMMEDIATELY after the add button is pressed.
                                        // Doesn't actually wait for artist to be selected from following controller.
                                        let controller = ArtistGroupSelectionViewController(appContext: self.appContext)
                                        controller.delegate = self
                                        self.selectingArtistGroupForIndex = index
                                        if let nav = self.navigationController {
                                            nav.pushViewController(controller, animated: true)
                                        } else {
                                            self.present(UINavigationController(rootViewController: controller),
                                                         animated: true,
                                                         completion: nil)
                                        }
                                        return UAPushRow<ArtistGroup> {
                                            $0.tag = FormFieldKeys.artistGroupAtIndex(index)
                                            $0.displayValueFor = {
                                                $0?.name
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
        guard let imageService = self.imageService else {
            showAlertForExtendedLocationPermissions()
            return
        }
        
        if let dateRow = self.form.rowBy(tag: FormFieldKeys.recordedAt) as? DateRow,
            let date = imageService.dateFromExif {
            dateRow.value = date
            dateRow.updateCell()
        }
        if let locationRow = self.form.rowBy(tag: FormFieldKeys.location) as? LocationRow {
            guard let placemark = imageService.placemarkFromExif else {
                showAlertForExtendedLocationPermissions()
                return
            }
            guard let location = placemark.location else {
                return
            }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if hideNavbarOnDisappear {
            navigationController?.setNavigationBarHidden(true, animated: true)
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
        
        if let title = formValues["title"] as? String {
            payload["title"] = title
        }
        
        // Artists
        let artistKeys: [String] = formValues.keys.filter { $0.contains("artist") && !$0.contains("button") }
        var artists: [Artist] = []
        for artistKey in artistKeys {
            if let artist = formValues[artistKey] as? Artist {
                artists.append(artist)
            }
        }
        log.debug("form values: \(formValues)")
        payload["artists"] = artists.map { String($0.id) }.joined(separator: ",")
        
        // ArtistGroups
        let artistGroupKeys: [String] = formValues.keys.filter { $0.contains("artist_group") && !$0.contains("button") }
        log.debug("artist group keys: \(artistGroupKeys)")
        var artistGroups: [ArtistGroup] = []
        for groupKey in artistGroupKeys {
            if let group = formValues[groupKey] as? ArtistGroup {
                artistGroups.append(group)
            }
        }
        payload["artist_groups"] = artistGroups.map { String($0.id) }.joined(separator: ",")
        log.debug("payload: \(payload)")
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
                                                self.save(body: payload)
                                            } else {
                                                self.newPostState = .initial
                                                self.showAlert(message: Strings.LocationLookupError)
                                            }
        })
    }

    func save(body: Parameters) {
        var payload = body
        guard let userID = self.appContext.store.user.data?.id else {
            log.error("no user")
            return
        }
        let secondsSince1970 = Int(Date().timeIntervalSince1970 * 1000)
        
        let imageID = "\(String(secondsSince1970))_\(String(userID))"
        print("image id: ", imageID)
        self.newPostState = .uploadingImages

        appContext.remoteImageService
            .uploadFile(data: selectedImageData, publicId: imageID, onCompletion: { success, error in
                guard success, error == nil else {
                    self.isLoading = false
                    self.newPostState = .initial
                    self.showAlert(message: "Unable to upload image")
                    return
                }
                self.newPostState = .savingPost
                // Create new Post and Post Images with filenames for uploaded images
                payload["filenames"] = [imageID]
                _ = self.networkService.request(PrivateRouter.createPost(values: payload),
                                           completion: { (result: UAResult<PostContainer>) in
                                            DispatchQueue.main.async {
                                                switch result {
                                                case .success(let container):
                                                    self.delegate?.createPostController(self, didCreatePost: container.post)
                                                    self.delegate?.createPostController(self, didUploadImageData: self.selectedImageData, forPost: container.post)
                                                    self.dismiss(animated: true, completion: nil)
                                                case .failure(let error):
                                                    self.isLoading = false
                                                    self.newPostState = .initial
                                                    self.showAlert(message: error.userMessage)
                                                }
                                            }
            })
        })
    }

    @objc func cancel(_ sender: UIBarButtonItem) {
        self.confirmDiscardChanges()
    }
    
    // MARK: - Private
    
    private func showAlertForExtendedLocationPermissions() {
        let alertController = UIAlertController(title: "We weren't able to fill in the location of this photo for you.", message: "Make sure Photo Library permissions are set to 'All photos' if you want location auto-filled", preferredStyle: .alert)
        let goToSettings = UIAlertAction(title: "Go to settings", style: .default, handler: { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    log.info("Settings opened: \(success)") // Prints true
                })
            }
            alertController.dismiss(animated: true, completion: nil)
        })
        let notNow = UIAlertAction(title: "Not now", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(goToSettings)
        alertController.addAction(notNow)
        
        presentAlertInCenter(alertController, animated: true, completion: nil)
    }
}

extension CreatePostViewController: ArtistSelectionDelegate {
    func artistSelectionController(_ controller: ArtistSelectionViewController, didSelectArtist artist: Artist?) {
        if let nav = controller.navigationController {
            nav.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true, completion: nil)
        }
        guard let artistsSection = self.form.sectionBy(tag: FormSectionKeys.artists) as? MultivaluedSection,
        let selectingAtIndex = self.selectingArtistForIndex else {
            return
        }
        guard let selectedArtist = artist else {
            // remove the empty row that is automatically added as soon as user hits add button
            artistsSection.remove(at: selectingAtIndex)
            return
        }
        
        if let artistRow: UAPushRow<Artist> = artistsSection.rowBy(tag: FormFieldKeys.artistAtIndex(selectingAtIndex)) {
            self.hasUnsavedChanges = true
            artistRow.value = selectedArtist
            artistRow.updateCell()
        }
    }
}
extension CreatePostViewController: ArtistGroupSelectionDelegate {
    func artistGroupSelectionController(_ controller: ArtistGroupSelectionViewController, didSelectArtistGroup artistGroup: ArtistGroup?) {
        
        if let nav = controller.navigationController {
            nav.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true, completion: nil)
        }
        guard let artistGroupsSection = self.form.sectionBy(tag: FormSectionKeys.artistGroups) as? MultivaluedSection,
        let selectingAtIndex = self.selectingArtistGroupForIndex else {
            return
        }
        guard let selectedGroup = artistGroup else {
            // remove the empty row that is automatically added as soon as user hits add button
            artistGroupsSection.remove(at: selectingAtIndex)
            return
        }
        if let artistGroupRow: UAPushRow<ArtistGroup> = artistGroupsSection.rowBy(tag: FormFieldKeys.artistGroupAtIndex(selectingAtIndex)) {
            self.hasUnsavedChanges = true
            artistGroupRow.value = selectedGroup
            artistGroupRow.updateCell()
        }
    }
    
    
}
