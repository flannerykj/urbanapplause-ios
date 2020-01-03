//
//  PostDetailViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import MapKit

protocol PostDetailDelegate: class {
    func postDetail(_ controller: PostDetailViewController, didUpdatePost post: Post)
    func postDetail(_ controller: PostDetailViewController, didBlockUser user: User)
    func postDetail(_ controller: PostDetailViewController, didDeletePost post: Post)
}

class PostDetailViewController: UIViewController {
    weak var delegate: PostDetailDelegate?
    var mainCoordinator: MainCoordinator
    var updatingCollections: [Collection] = []
    var addedToCollections: [Collection] = []
    
    var post: Post? {
        didSet {
            guard let post = post else { return }
            title = post.title
            if let file = post.PostImages?.first {
                downloadJob = mainCoordinator.fileCache.getJobForFile(file)
            }
            artistLabel.text = post.title
            setLocation(post.Location)
            setUser(post.User)
            setArtists(post.Artists ?? [])
            dateLabel.text = post.createdAt?.timeSince()
            
            mapView.addAnnotation(post)
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            let region = MKCoordinateRegion(center: post.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            updateVisitedButton()
            updateApplaudedButton()
        }
    }
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    var markerReuseIdentifier = "PostDetailMarker"
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                self.downloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    init(postId: Int, post: Post?, thumbImage: UIImage? = nil, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        
        super.init(nibName: nil, bundle: nil)
        
        self.post = post
        photoView.state = .complete(thumbImage)
        self.fetchPost(postID: postId)
    }
    
    let activityIndicator = ActivityIndicator()
    
    func fetchPost(postID: Int) {
        self.isLoading = true
        _ = mainCoordinator.networkService.request(PrivateRouter.getPost(id: postID),
                                                   completion: { (result: UAResult<PostContainer>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let container):
                    self.post = container.post
                case .failure(let error):
                    log.error(error)
                    self.showAlert(title: "Something went wrong", message: error.userMessage)
                }
            }
        })
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var downloadJob: FileDownloadJob? {
        didSet {
            guard let job = downloadJob else { log.debug("job is nil"); return }
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    self.photoView.state = .complete(UIImage(data: data))
                }
            }, onError: { error in
                DispatchQueue.main.async {
                    self.photoView.state = .error(error)
                }
            }, onUpdateProgress: { progress in
                DispatchQueue.main.async {
                    self.photoView.state = .downloading(progress)
                }
            })
        }
    }

    var downloadedImages: [Int: UIImage] = [:]
        
    lazy var photoView = LoadableImageView(initialState: .empty)
    
    var artistLabel: UILabel = {
        let label = UILabel()
        label.style(as: .h2)
        return label
    }()
    lazy var locationLabel: UITextView = {
        let textView = UATextView()
        textView.delegate = self
        return textView
    }()
    var dateLabel: UILabel = {
        let label = UILabel()
        label.style(as: .body)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    lazy var postedByTextView: UATextView = {
        let textView = UATextView()
        textView.delegate = self
        return textView
    }()
    
    func setUser(_ user: User?) {
        guard let userId = user?.id else { postedByTextView.text = ""; return }
        let username = user?.username ?? ""
        let text = "Posted by \(username)"
        let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(string: text))
        attributedText.style(as: .body)
        attributedText.style(as: .link,
                             withLink: "www.urbanapplause.com/app/users/\(username)",
            for: NSRange(location: (text.count - username.count), length: username.count))
        postedByTextView.attributedText = attributedText
    }
    
    lazy var artistsTextView: UATextView = {
        let textView = UATextView()
        textView.delegate = self
        return textView
    }()
    
    func setArtists(_ artists: [Artist]) {
        let prependText = "Artists: "
        
        let artistNames = artists.filter {
            $0.signing_name != nil
        }.map { $0.signing_name ?? "" }
        let artistNameSeperator = ", "

        var allText = prependText
        let noneAddedText = "None added"
        if artistNames.count > 0 {
            allText += artistNames.joined(separator: artistNameSeperator)
        } else {
            allText += noneAddedText
        }
        let attributedString = NSAttributedString(string: allText)
        let attributedText = NSMutableAttributedString(attributedString: attributedString)
        
        attributedText.style(as: .body)
        
        var charIndex: Int = prependText.count
        for artist in artists {
            guard let name = artist.signing_name else { continue }
            attributedText.style(as: .link,
                                 withLink: "www.urbanapplause.com/app/artists/\(artist.id)",
                for: NSRange(location: charIndex, length: name.count))
            charIndex += name.count + artistNameSeperator.count
        }
        
        if artistNames.count == 0 {
            attributedText.style(as: .placeholder,
                                 for: NSRange(location: prependText.count, length: noneAddedText.count))
        }
        
        artistsTextView.attributedText = attributedText
    }
    
    func setLocation(_ optionalLocation: Location?) {
        guard let location = optionalLocation else { locationLabel.text = ""; return }
        let prependText = "Location: "
        let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(string: prependText + location.description))
        attributedText.style(as: .body)
        attributedText.style(as: .link, withLink: "www.urbanapplause.com/app/locations/\(location.id)", for: NSRange(location: prependText.count, length: location.description.count))
        locationLabel.attributedText = attributedText
    
    }
    lazy var metadataStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [postedByTextView, dateLabel, locationLabel, artistsTextView])
        postedByTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        dateLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        locationLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        artistsTextView.setContentCompressionResistancePriority(.required, for: .vertical)

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: StyleConstants.contentPadding,
                                               left: StyleConstants.contentPadding,
                                               bottom: StyleConstants.contentPadding,
                                               right: StyleConstants.contentPadding)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    let visitsButton = UAButton(type: .outlined,
                                title: "Visited",
                                target: self,
                                action: #selector(toggleVisited(_:)),
                                rightImage: UIImage(systemName: "eye"))
    
    let applaudedButton = UAButton(type: .outlined,
                                        title: "Applauded",
                                        target: self,
                                        action: #selector(toggleApplause(_:)),
                                        rightImage: UIImage(named: "applause"))
    
    lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [visitsButton, applaudedButton])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: StyleConstants.contentPadding,
                                               left: StyleConstants.contentPadding,
                                               bottom: StyleConstants.contentPadding,
                                               right: StyleConstants.contentPadding)
        return stackView
    }()
    lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [photoView,
                                                       metadataStackView,
                                                       optionsStackView,
                                                       mapView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()

    lazy var mapView: MKMapView = {
       let mapView = MKMapView()
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: markerReuseIdentifier)
        return mapView
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        contentStackView.fill(view: scrollView)
        contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        return scrollView
    }()
    
    lazy var optionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(showMoreOptions(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(showImageDetail(_:)))
        photoView.isUserInteractionEnabled = true
        photoView.addGestureRecognizer(gr)
        // nav setup
        view.backgroundColor = UIColor.backgroundMain
        // let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        navigationItem.rightBarButtonItem = optionsButton
        
        view.addSubview(scrollView)

        scrollView.fill(view: self.view)
        NSLayoutConstraint.activate([
        photoView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.4),
        mapView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height * 0.5)
        ])
        view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        visitsButton.setLeftImage(UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
        applaudedButton.setLeftImage(UIImage(named: "applause")?.withRenderingMode(.alwaysTemplate))

        let thegrey = UIColor.systemGray
        visitsButton.normalProperties.borderColor = thegrey
        visitsButton.normalProperties.textColor = thegrey
        applaudedButton.normalProperties.borderColor = thegrey
        applaudedButton.normalProperties.textColor = thegrey
        applaudedButton.selectedProperties.backgroundColor = UIColor.systemPink
        applaudedButton.selectedProperties.borderColor = UIColor.systemPink
        
        self.updateVisitedButton()
        self.updateApplaudedButton()

    }
    @objc func showMoreOptions(_ sender: UIButton) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let savePostAction = UIAlertAction(title: "Save to gallery", style: .default, handler: { _ in
            self.savePost()
        })
        alertController.addAction(savePostAction)
        
        if let user = mainCoordinator.store.user.data,
            let post = self.post, post.UserId == user.id {
            let deleteAction = UIAlertAction(title: "Delete post", style: .default, handler: { _ in
                self.confirmDeletePost()
            })
            alertController.addAction(deleteAction)
        } else {
            let reportPostAction = UIAlertAction(title: "Report this post", style: .default, handler: { _ in
                self.flagPost()
            })
            let blockActionTitle = "Block \(post?.User?.username ?? "this user")"
            let blockAction = UIAlertAction(title: blockActionTitle, style: .default, handler: { _ in
                guard let user = self.post?.User else { return }
                self.blockUser(user)
            })
            alertController.addAction(reportPostAction)
            alertController.addAction(blockAction)
        }
        
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancel)
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        present(alertController, animated: true, completion: nil)
    }
    @objc func showImageDetail(_: Any) {
        let vc = ImageCarouselViewController(files: self.post?.PostImages ?? [], mainCoordinator: mainCoordinator)
        navigationController?.pushViewController(vc, animated: true)
    }
    @objc func edit(_ sender: UIBarButtonItem) {
        let editVc = NewPostViewController(mainCoordinator: mainCoordinator)
        editVc.editingPost = post
        editVc.savedImages = downloadedImages
        // editVc.delegate = self
        present(UINavigationController(rootViewController: editVc), animated: true)
    }

    @objc func toggleVisited(_ sender: UIButton) {
        guard self.mainCoordinator.authService.isAuthenticated else {
            self.showAlertForLoginRequired(desiredAction: "save a visit",
                                           mainCoordinator: self.mainCoordinator)
            return
        }
        guard let user = mainCoordinator.store.user.data,
            let post = self.post else {
                return
        }
        let endpoint = PrivateRouter.addOrRemoveVisit(postId: post.id, userId: user.id)
        _ = mainCoordinator.networkService.request(endpoint) { (result: UAResult<VisitInteractionContainer>) in
            switch result {
            case .success(let container):
                DispatchQueue.main.async {
                    if container.deleted {
                        self.post?.Visits?.removeAll { interaction in
                            interaction.id == container.visit.id
                        }
                    } else {
                        self.post?.Visits?.append(container.visit)
                    }
                    self.updateVisitedButton()
                }
            case .failure(let error):
                log.error(error)
            }
        }
    }
    
    func updateVisitedButton() {
        if let userId = self.mainCoordinator.store.user.data?.id,
            let visited = self.post?.Visits?.contains(where: { $0.UserId == userId }) {
            
            visitsButton.isSelected = visited
            visitsButton.setTitle(visited ? "Visited" : "Mark as visited", for: .normal)
        }
    }
    
    @objc func toggleApplause(_: Any) {
        guard self.mainCoordinator.authService.isAuthenticated else {
            self.showAlertForLoginRequired(desiredAction: "applaud",
                                           mainCoordinator: self.mainCoordinator)
            return
        }
        
        guard let post = self.post,
            let userId = mainCoordinator.store.user.data?.id else {
                log.error("missing data for creating applause")
                return
        }
        _ = mainCoordinator.networkService.request(PrivateRouter.addOrRemoveClap(postId: post.id, userId: userId),
                                                   completion: { (result: UAResult<ApplauseInteractionContainer>) in
                                                    switch result {
                                                    case .success(let container):
                                                        DispatchQueue.main.async {
                                                            if container.deleted {
                                                                self.post?.Claps?.removeAll { interaction in
                                                                    interaction.id == container.clap.id
                                                                }
                                                            } else {
                                                                self.post?.Claps?.append(container.clap)
                                                            }
                                                            self.updateApplaudedButton()
                                                        }
                                                    case .failure(let error):
                                                        log.error(error)
                                                    }
        })
    }
    func updateApplaudedButton() {
        if let userId = self.mainCoordinator.store.user.data?.id,
            let applauded = self.post?.Claps?.contains(where: { $0.UserId == userId }) {
            applaudedButton.isSelected = applauded
            applaudedButton.setTitle(applauded ? "Applauded" : "Applaud", for: .normal)
        }
    }
    
    func blockUser(_ user: User) {
        guard let blockingUser = mainCoordinator.store.user.data else { return }
        let username = user.username ?? "this user"
        let msg = "You will no longer be show posts or comments from this user"
        let alertController = UIAlertController(title: "Block \(username)?", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        let blockAction = UIAlertAction(title: "Block", style: .destructive, handler: { _ in
            let endpoint = PrivateRouter.blockUser(blockingUserId: blockingUser.id, blockedUserId: user.id)
            _ = self.mainCoordinator.networkService.request(endpoint,
                                                       completion: { (result: UAResult<BlockedUserContainer>) in
                                                        DispatchQueue.main.async {
                                                            switch result {
                                                            case .success:
                                                                self.onBlockUserSuccess(user: user)
                                                            case .failure(let error):
                                                                self.onBlockUserError(error, user: user)
                                                            }
                                                        }
            })
        })
        alertController.addAction(cancelAction)
        alertController.addAction(blockAction)
        presentAlertInCenter(alertController)
        
    }
    
    func onBlockUserSuccess(user: User) {
        let username = user.username ?? "This user"
        let successMsg = "\(username) has been blocked"
        let successAlert = UIAlertController(title: successMsg,
                                             message: nil,
                                             preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            successAlert.dismiss(animated: true, completion: nil)
        })
        successAlert.addAction(okAction)
        self.present(successAlert, animated: true, completion: nil)
        
        delegate?.postDetail(self, didBlockUser: user)
        if let nav = self.navigationController, nav.viewControllers.first != self {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func onBlockUserError(_ error: UAError, user: User) {
        log.error(error)
        let errorAlert = UIAlertController(title: "Unable to complete request",
                                           message: error.userMessage,
                                           preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            errorAlert.dismiss(animated: true, completion: nil)
        })
        errorAlert.addAction(okAction)
        self.present(errorAlert, animated: true, completion: nil)
    }
    func confirmDeletePost() {
        guard let post = self.post else { return }
        let alertController = UIAlertController(title: "Are you sure you want to delete this post?",
                                                message: "This cannot be undone.",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            _ = self.mainCoordinator.networkService.request(PrivateRouter.deletePost(id: post.id),
                                                       completion: { (result: UAResult<PostContainer>) in
                                                        DispatchQueue.main.async {
                                                            switch result {
                                                            case .success:
                                                                self.onDeletePostSuccess(post: post)
                                                            case .failure(let error):
                                                                self.onDeletePostError(error, post: post)
                                                            }
                                                        }
            })
        })
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true, completion: nil)
    }
    func savePost() {
        guard let userId = mainCoordinator.store.user.data?.id else {
            return
        }
        let galleriesViewModel = GalleryListViewModel(userId: userId,
                                                      includeGeneratedGalleries: false,
                                                      mainCoordinator: mainCoordinator)
        
        let vc = GalleryListViewController(viewModel: galleriesViewModel,
                                           mainCoordinator: mainCoordinator)
        vc.navigationItem.title = "Add to galleries"
        vc.delegate = self
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    func onDeletePostSuccess(post: Post) {
        self.post = post
        delegate?.postDetail(self, didDeletePost: post)
        if let nav = self.navigationController, nav.viewControllers.first != self {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
        
        let successAlert = UIAlertController(title: "Your post has been deleted.",
                                             message: nil,
                                             preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            successAlert.dismiss(animated: true, completion: nil)
        })
        successAlert.addAction(okAction)
        self.present(successAlert, animated: true, completion: nil)
    }
    func onDeletePostError(_ error: UAError, post: Post) {
        log.error(error)
        let errorAlert = UIAlertController(title: "Unable to complete request",
                                           message: error.userMessage,
                                           preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            errorAlert.dismiss(animated: true, completion: nil)
        })
        errorAlert.addAction(okAction)
        self.present(errorAlert, animated: true, completion: nil)
    }
    func flagPost() {
        let vc = ReportAnIssueViewController(store: mainCoordinator.store) { reportController, reason in
            self.submitFlag(reason: reason, reportAnIssueController: reportController)
        }
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }

    func addPostToCollection(_ collection: Collection, completion: @escaping (Bool) -> Void) {
        guard let post = self.post else { return }
        let endpoint = PrivateRouter.addToCollection(collectionId: collection.id, postId: post.id, annotation: "")
        _ = mainCoordinator.networkService.request(endpoint, completion: { (result: UAResult<CollectionContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let container):
                    post.Collections = [container.collection] + (post.Collections ?? [])
                    self.post = post
                    self.delegate?.postDetail(self, didUpdatePost: post)
                    completion(true)
                case .failure(let error):
                    log.error(error)
                    completion(false)
                }
            }
        })
    }
    
    func removePostFromCollection(_ collection: Collection, completion: @escaping (Bool) -> Void) {
        guard let post = self.post else { return }
        let endpoint = PrivateRouter.deleteFromCollection(collectionId: collection.id, postId: post.id)
        _ = mainCoordinator.networkService.request(endpoint, completion: { (result: UAResult<CollectionContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let container):
                    post.Collections?.removeAll { collection in
                        collection.id == container.collection.id
                    }
                    self.post = post
                    self.delegate?.postDetail(self, didUpdatePost: post)
                    completion(true)
                case .failure(let error):
                    log.error(error)
                    completion(false)
                }
            }
        })
    }
    func submitFlag(reason: PostFlagReason, reportAnIssueController: ReportAnIssueViewController) {
        guard let post = self.post else { return }
        reportAnIssueController.self.isSubmitting = true
        _ = mainCoordinator.networkService.request(PrivateRouter.createPostFlag(postId: post.id,
                                                                                reason: reason),
                                                   completion: { (result: UAResult<PostFlagContainer>) in
                                                    DispatchQueue.main.async {
                                                        reportAnIssueController.self.isSubmitting = false
                                                        switch result {
                                                        case .success(let container):
                                                            log.debug(container)
                                                            reportAnIssueController.didSubmit = true
                                                        case .failure(let error):
                                                            log.error(error)
                                                            reportAnIssueController.handleError(error: error)
                                                        }
                                                    }
        })
    }
}

extension PostDetailViewController: PostFormDelegate {
    func didCreatePost(post: Post) {}

    func didDeletePost(post: Post) {
        DispatchQueue.main.async {
            // self.delegate?.shouldReloadPosts()
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension PostDetailViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: markerReuseIdentifier)
        annotationView?.annotation = annotation
        return annotationView
    }
}

extension PostDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.pathComponents.contains("artists") {
            guard let idString = URL.pathComponents.last else { return false }
            guard let artist = self.post?.Artists?.first(where: {
                return $0.id == Int(idString)
            }) else { return false }
            let vc = ArtistProfileViewController(artist: artist,
                                                 mainCoordinator: mainCoordinator)
            navigationController?.pushViewController(vc, animated: true)
        }
        if URL.pathComponents.contains("users") {
            // guard let idString = URL.pathComponents.last, let id = Int(idString) else { return false }
            guard let user = self.post?.User else { return false }
            let vc = ProfileViewController(user: user, mainCoordinator: mainCoordinator)
            navigationController?.pushViewController(vc, animated: true)
        }
        if URL.pathComponents.contains("locations") {
            guard let location = self.post?.Location else {
                return false
            }
            let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "Get directions", style: .default, handler: { _ in
                let placemark = MKPlacemark(coordinate: location.clLocation.coordinate)
                let mapItem = MKMapItem(placemark: placemark)

                mapItem.name = location.description
                let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeWalking]
                mapItem.openInMaps(launchOptions: launchOptions)
            }))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(ac, animated: true, completion: nil)
        }
        
        return false
    }
}

extension PostDetailViewController: GalleryListDelegate {
        func galleryList(_ controller: GalleryListViewController,
                     didSelectCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) {
        
        guard case let Gallery.custom(collection) = cellModel.gallery else { return }
        
        if updatingCollections.firstIndex(where: {
            $0.id == collection.id
        }) != nil {
            return
        }
        
        let updatingIndex = self.updatingCollections.count
        self.updatingCollections.append(collection)
        
        let firstIndex = addedToCollections.firstIndex(where: {
            $0.id == collection.id
        })
        if firstIndex != nil {
            self.removePostFromCollection(collection, completion: { success in
                if success {
                    self.addedToCollections.removeAll(where: {
                        $0.id == collection.id
                    })
                }
                self.updatingCollections.remove(at: updatingIndex)
                controller.reloadGalleryCells([cellModel], animate: true)
            })
        } else {
            self.addPostToCollection(collection, completion: { success in
                if success {
                    self.addedToCollections.append(collection)
                }
                self.updatingCollections.remove(at: updatingIndex)
                controller.reloadGalleryCells([cellModel], animate: true)
            })
        }
        controller.reloadGalleryCells([cellModel], animate: true)
    }
    
    func galleryList(_ controller: GalleryListViewController,
                     accessoryViewForCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) -> UIView? {
        
        if case let Gallery.custom(collection) = cellModel.gallery {
            if updatingCollections.contains(where: {
                $0.id == collection.id
            }) {
                let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                activityIndicator.style = UIActivityIndicatorView.Style.medium
                activityIndicator.startAnimating()
                return activityIndicator
            }
            if addedToCollections.contains(where: {
                $0.id == collection.id
            }) {
                return UIImageView(image: UIImage(systemName: "checkmark"))
            }
        }
        return nil
    }
    
    
}
