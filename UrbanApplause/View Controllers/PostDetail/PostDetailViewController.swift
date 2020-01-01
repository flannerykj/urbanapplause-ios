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
            guard let post = post else { return }
            title = post.title
            toolbarVC.post = post
            if let file = post.PostImages?.first {
                downloadJob = mainCoordinator.fileCache.getJobForFile(file)
            }
            artistLabel.text = post.title
            locationLabel.text = post.Location?.description
            setUsername(post.User?.username)
            setArtists(post.Artists ?? [])
            dateLabel.text = post.createdAt?.timeSince()
            
            mapView.addAnnotation(post)
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            let region = MKCoordinateRegion(center: post.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            updateVisitedButton()
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
    var locationLabel: UILabel = {
        let label = UILabel(type: .body)
        label.font = TypographyStyle.strong.font
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
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
    
    func setUsername(_ username: String?) {
        let username = username ?? ""
        let text = "Posted by \(username)"
        let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(string: text))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        attributedText.setAttributes([
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: TypographyStyle.body.font,
            NSAttributedString.Key.foregroundColor: TypographyStyle.body.color
        ], range: NSRange(location: 0, length: text.count))
        
        attributedText.setAttributes([
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: TypographyStyle.link.font,
            NSAttributedString.Key.link: "",
            NSAttributedString.Key.foregroundColor: TypographyStyle.link.color
        ], range: NSRange(location: (text.count - username.count), length: username.count))
        postedByTextView.attributedText = attributedText
    }
    
    lazy var artistsTextView: UATextView = {
        let textView = UATextView()
        textView.delegate = self
        return textView
    }()
    
    func setArtists(_ artists: [Artist]) {
        var text = "Artists: "
        let artistNames = artists.filter { $0.signing_name != nil }.map { $0.signing_name ?? "" }.joined(separator: ", ")
        text += artistNames
        
        let attributedText = NSMutableAttributedString(attributedString: NSAttributedString(string: text))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        
        attributedText.setAttributes([
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: TypographyStyle.body.font,
            NSAttributedString.Key.foregroundColor: TypographyStyle.body.color
        ], range: NSRange(location: 0, length: text.count))
        
        attributedText.setAttributes([
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: TypographyStyle.link.font,
            NSAttributedString.Key.link: "",
            NSAttributedString.Key.foregroundColor: TypographyStyle.link.color
        ], range: NSRange(location: (text.count - artistNames.count), length: artistNames.count))
        artistsTextView.attributedText = attributedText
    }
    lazy var topContentLeftStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [postedByTextView, dateLabel, locationLabel, artistsTextView])
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

    lazy var toolbarVC = PostToolbarController(mainCoordinator: mainCoordinator)
    
    lazy var dividerView: UIView = {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 12).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let visitsButton = UAButton(type: .outlined,
                                title: "Visited",
                                target: self,
                                action: #selector(toggleVisited(_:)),
                                rightImage: UIImage(systemName: "eye"))
    
    
    lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [visitsButton])
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
                                                       topContentLeftStackView,
                                                       toolbarVC.view,
                                                       optionsStackView,
                                                       mapView])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        contentStackView.fill(view: scrollView)
        contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        return scrollView
    }()
    
    lazy var mapView: MKMapView = {
       let mapView = MKMapView()
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: markerReuseIdentifier)
        return mapView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(showImageDetail(_:)))
        photoView.isUserInteractionEnabled = true
        photoView.addGestureRecognizer(gr)
        toolbarVC.delegate = self
        toolbarVC.mainCoordinator = mainCoordinator
        // nav setup
        view.backgroundColor = UIColor.backgroundMain
        // let editButton = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(edit))
        // navigationItem.rightBarButtonItem = editButton
        
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            scrollView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            photoView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.4),
            mapView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        ])
        
        view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        visitsButton.setLeftImage(UIImage(systemName: "checkmark")?.withRenderingMode(.alwaysTemplate))
        
        let thegrey = UIColor.systemGray
        visitsButton.normalProperties.borderColor = thegrey
        visitsButton.normalProperties.textColor = thegrey
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
    @objc func didSelectUser(_: Any) {
        guard let user = post?.User else { return }
        // let vc = ProfileViewController(user: user, mainCoordinator: mainCoordinator)
        // navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func toggleVisited(_ sender: UIButton) {
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
        if let visited = self.post?.Visits?.contains(where: { $0.UserId == self.mainCoordinator.store.user.data?.id }) {
            visitsButton.isSelected = visited
            visitsButton.setTitle(visited ? "Visited" : "Mark as visited", for: .normal)
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
        /// go to user profile
        log.debug("go to user profile")
        return false
    }
}
