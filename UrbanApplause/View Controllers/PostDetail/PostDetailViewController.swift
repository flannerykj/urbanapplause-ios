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
    var imageDownloadJobs: [FileDownloadJob] = []
    var post: Post? {
        didSet {
            guard let post = post else { return }
            title = post.title
            toolbarVC.post = post
            if let file = post.PostImages?.first {
                downloadJob = mainCoordinator.fileCache.download(file: file)
            }
            artistLabel.text = post.title
            locationLabel.text = post.Location?.description
            usernameButton.setTitle(post.User?.username, for: .normal)
            usernameButton.style(as: .link)
            dateLabel.text = post.createdAt?.timeSince()
            
            mapView.addAnnotation(post)
            let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
            let region = MKCoordinateRegion(center: post.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            if let images = post.PostImages {
                var jobs = [FileDownloadJob]()
                for file in images {
                    if let imageJob = mainCoordinator.fileCache.download(file: file) {
                        jobs.append(imageJob)
                    }
                }
                self.imageDownloadJobs = jobs
            }
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
        photoView.image = thumbImage
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
                    self.photoView.image = UIImage(data: data)
                }
            })
        }
    }

    var downloadedImages: [Int: UIImage] = [:]
    
    lazy var photoView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        view.image = UIImage(named: "placeholder")
        return view
    }()
    var artistLabel: UILabel = {
        let label = UILabel()
        label.style(as: .h2)
        return label
    }()
    var locationLabel: UILabel = {
        let label = UILabel(type: .body)
        label.font = UIFont(name: Helvetica.bold.rawValue, size: 15)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    var dateLabel: UILabel = {
        let label = UILabel()
        label.style(as: .body)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    lazy var usernameButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.style(as: .link)
        button.addTarget(self, action: #selector(didSelectUser(_:)), for: .touchUpInside)
        return button
    }()
    lazy var usernameRow: UIStackView = {
        let postedBy = UILabel()
        postedBy.text = "Posted by "
        postedBy.style(as: .body)
        let stackView = UIStackView(arrangedSubviews: [postedBy, usernameButton, NoFrameView()])
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    lazy var topContentLeftStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [usernameRow, locationLabel])
        stackView.axis = .vertical
        stackView.spacing = -8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    lazy var topContentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [topContentLeftStackView, NoFrameView(), dateLabel])
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0,
                                               left: StyleConstants.contentPadding,
                                               bottom: StyleConstants.contentPadding,
                                               right: StyleConstants.contentPadding)
        return stackView
    }()
    lazy var toolbarVC = PostToolbarController(mainCoordinator: mainCoordinator)
    lazy var dividerView: UIView = {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 12).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [photoView, topContentStackView, toolbarVC.view, mapView])
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
        let vc = ProfileViewController(user: user, mainCoordinator: mainCoordinator)
        navigationController?.pushViewController(vc, animated: true)
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
