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
    
    var post: Post? {
        didSet {
            commentsVC.post = post
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
            self.updateContentView()
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
        attributedText.addAttributes([.link: "www.urbanapplause.com/app/locations/\(location.id)"],
                                     range: NSRange(location: prependText.count, length: location.description.count))
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

    lazy var commentListViewModel = CommentListViewModel(post: self.post,
                                                         mainCoordinator: mainCoordinator)
    
    lazy var commentsVC = CommentListViewController(viewModel: commentListViewModel,
                                                    mainCoordinator: mainCoordinator)
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(showImageDetail(_:)))
        photoView.isUserInteractionEnabled = true
        photoView.addGestureRecognizer(gr)
        // nav setup
        view.backgroundColor = UIColor.backgroundMain
        // let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        // navigationItem.rightBarButtonItem = editButton
        
        let tableView = commentsVC.tableView

        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
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
    }
    func updateContentView() {
        let tableView = commentsVC.tableView
        let sizeThatFits = contentStackView.systemLayoutSizeFitting(CGSize(width: self.view.frame.width, height: 1), withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
        let tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: sizeThatFits.height))
        tableView.backgroundColor = .clear
        tableHeaderView.addSubview(contentStackView)
        contentStackView.fill(view: tableHeaderView)
        tableView.tableHeaderView = tableHeaderView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentView()
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

extension PostDetailViewController: PostToolbarDelegate {
    func postToolbar(_ toolbar: PostToolbarController, didBlockUser user: User) {
        delegate?.postDetail(self, didBlockUser: user)
        if let nav = self.navigationController, nav.viewControllers.first != self {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func postToolbar(_ toolbar: PostToolbarController, didUpdatePost post: Post) {
        self.post = post
        delegate?.postDetail(self, didUpdatePost: post)
    }
    func postToolbar(_ toolbar: PostToolbarController, didDeletePost post: Post) {
        self.post = post
        delegate?.postDetail(self, didDeletePost: post)
        if let nav = self.navigationController, nav.viewControllers.first != self {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
extension PostDetailViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.pathComponents.contains("artists") {
            guard let idString = URL.pathComponents.last else { return false }
            guard let artist = self.post?.Artists?.first(where: {
                return $0.id == Int(idString)
            }) else { return false }

            let viewModel = ArtistProfileViewModel(artistId: artist.id,
                                                   artist: artist,
                                                   mainCoordinator: mainCoordinator)
            
            let vc = ArtistProfileViewController(viewModel: viewModel,
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
