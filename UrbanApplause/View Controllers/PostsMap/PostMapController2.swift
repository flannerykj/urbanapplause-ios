//
//  PostMapController2.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Shared
import SnapKit
import RxSwift

class PostMapViewController2: UIViewController {
    private let disposeBag = DisposeBag()
    
    var viewModel: MapDataStream
    var appContext: AppContext
    var needsUpdate: Bool = false
    var awaitingZoomToCurrentLocation: Bool = false

    lazy var scaleView: MKScaleView = MKScaleView(mapView: mapView)
    
    // Create a location manager to trigger user tracking
    var locationManager = CLLocationManager()
    var requestedZoomToCurrentLocation: Bool = false
    
    init(viewModel: MapDataStream, appContext: AppContext) {
        self.appContext = appContext
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    private func subscribeToMapData() {
        viewModel.error
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (err: Error?) in
                if let err = err {
                    self.handleError(err)
                }
            })
            .disposed(by: disposeBag)
        
        
        viewModel.mapMarkers
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { clustersAdded in
                self.mapView.removeAnnotations(self.mapView.annotations)
                if let clusters = clustersAdded {
                    self.mapView.addAnnotations(clusters)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { isLoading in
                self.loadingView.isHidden = !isLoading
            })
            .disposed(by: disposeBag)
    }
    let activityIndicator = CircularLoader()
    
    lazy var loadingView: UIView = {
        let view = UIView()
        activityIndicator.heightAnchor.constraint(equalToConstant: 24).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 24).isActive = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.tintColor = UIColor.systemPink
        activityIndicator.animate()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layoutMargins = StyleConstants.defaultPaddingInsets
        view.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        return view
    }()
    
    // MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let username = self.appContext.store.user.data?.username {
            navigationItem.title = Strings.WelcomeMessage(username: username)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }

        mapView.addSubview(loadingView)
        loadingView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor).isActive = true
        loadingView.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
        let backItem = UIBarButtonItem()
        backItem.title = Strings.MapTabItemTitle
        navigationItem.backBarButtonItem = backItem
        
        let locationButton = UIBarButtonItem(image: UIImage(systemName: "location"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(requestZoomToCurrentLocation(_:)))
        
        navigationItem.rightBarButtonItem = locationButton

        let gr = UILongPressGestureRecognizer(target: self, action: #selector(longPressedMap(sender:)))
        mapView.addGestureRecognizer(gr)
        
        subscribeToMapData()
    }
    
    @objc func longPressedMap(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            let touchPoint = sender.location(in: self.mapView)
            let touchCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: touchCoordinate.latitude,
                                                                           longitude: touchCoordinate.longitude),
                                        addressDictionary: [:])
            
            let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let addPost = UIAlertAction(title: Strings.AddPostHereButtonTitle, style: .default, handler: { _ in
                self.addNewPost(sender: self.mapView, at: placemark)
            })
            
            let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)
            ac.addAction(addPost)
            ac.addAction(cancelAction)
            ac.popoverPresentationController?.sourceView = self.mapView
            ac.popoverPresentationController?.sourceRect = CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0)
            present(ac, animated: true, completion: nil)
        }
    }
    
    func addNewPost(sender: UIView, at placemark: CLPlacemark?) {
        (self.tabBarController as? TabBarController)?.getImageForNewPost(sender: sender, placemark: placemark)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(frame: self.view.frame)
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.layoutMargins = UIEdgeInsets(top: AnnotationContentView.height, left: AnnotationContentView.width/2, bottom: 0, right: AnnotationContentView.width/2)
        mapView.register(PostGISClusterAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        mapView.register(PostAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        mapView.register(PostMKClusterAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        return mapView
    }()
    
    @objc func tappedAnnotation(sender: UITapGestureRecognizer) {
        guard let annotationView = sender.view as? MKAnnotationView else { return }
        let thumbImage = (sender.view as? PostAnnotationViewProtocol)?.contentView.getImage()

        if let annotation = annotationView.annotation as? MKClusterAnnotation {
            if let members = annotation.memberAnnotations as? [Post] {
                if viewModel.isAtMaxZoom(visibleMapRect: mapView.visibleMapRect,
                                         mapPixelWidth: Double(mapView.bounds.width)) {
                    
                    let wallViewModel = PostListViewModel(posts: members, appContext: appContext)
                    let wallController = PostListViewController(viewModel: wallViewModel,
                                                                appContext: appContext)
                    wallController.postListDelegate = self
                    navigationController?.pushViewController(wallController, animated: true)
                } else {
                    self.mapView.showAnnotations(members, animated: true)
                }
            } else if let members = annotation.memberAnnotations as? [PostCluster],
                let region = self.viewModel.getRegionForClusters(members, mapBounds: self.mapView.bounds) {
                self.mapView.setRegion(region,
                                       animated: true)
            }
        } else if let post = annotationView.annotation as? Post {
            showDetailForPostWithID(post.id, post: post, thumbImage: thumbImage)
        } else if let postCluster = annotationView.annotation as? PostCluster {
            if postCluster.count == 1 {
                showDetailForPostWithID(postCluster.cover_post_id, post: nil, thumbImage: thumbImage)
            } else if let region = viewModel.getRegionForCluster(postCluster, mapBounds: self.mapView.bounds) {
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    func showDetailForPostWithID(_ postID: Int, post: Post?, thumbImage: UIImage?) {
        let viewController = PostDetailViewController(postId: postID,
                                                      post: post,
                                                      thumbImage: thumbImage,
                                                      appContext: appContext)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
    func handleError(_ error: Error) {
        log.error(error)
        let message = (error as? UAError)?.userMessage ?? error.localizedDescription
        showAlert(title: Strings.ErrorAlertTitle, message: message)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMap()
    }
    
    func updateMap(refreshCache: Bool = false) {
        log.debug("refreshCache: \(refreshCache)")
        if refreshCache {
            viewModel.resetCache()
        }
        viewModel.requestMapData(visibleMapRect: mapView.visibleMapRect,
                                 mapPixelWidth: Double(mapView.bounds.width),
                                 forceReload: refreshCache)
    }
    @objc func requestZoomToCurrentLocation(_: Any) {
        guard CLLocationManager.locationServicesEnabled() else {
            showAlert(message: Strings.LocationServicesNotEnabledError)
            return
        }
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            awaitingZoomToCurrentLocation = true
        case .restricted, .denied:
            showAlertForDeniedPermissions(permissionType: Strings.LocationPermissionType)
        case .authorizedAlways, .authorizedWhenInUse:
            if let location = locationManager.location {
                self.zoomToLocation(location)
            } else {
                awaitingZoomToCurrentLocation = true
                locationManager.requestWhenInUseAuthorization()
                locationManager.requestLocation()
            }
        @unknown default:
            log.error("unknwon auth status: \(CLLocationManager.authorizationStatus())")
        }
    }
    func zoomToLocation(_ location: CLLocation) {
        let region = MKCoordinateRegion(center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
}

extension PostMapViewController2: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let postGISClusterAnnotation = annotation as? PostCluster {
            // receiving clusters from backend - green
            return PostGISClusterAnnotationView(annotation: postGISClusterAnnotation, reuseIdentifier: PostGISClusterAnnotationView.reuseIdentifier)
        } else if let postAnnotation = annotation as? Post {
            // receiving posts from backend - blue
            return PostAnnotationView(annotation: postAnnotation, reuseIdentifier: PostAnnotationView.reuseIdentifier)
        }
        log.debug("returning nil for annotation: \(annotation)")
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            let gr = UITapGestureRecognizer(target: self, action: #selector(tappedAnnotation(sender:)))
            view.addGestureRecognizer(gr)
            if let annotationView = view as? PostGISClusterAnnotationView {
                annotationView.fileCache = appContext.fileCache
            }
            if let annotationView = view as? PostMKClusterAnnotationView {
                annotationView.fileCache = appContext.fileCache
            }
            if let annotationView = view as? PostAnnotationView {
                annotationView.fileCache = appContext.fileCache
            }
        }
    }
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        // called while user is moving the screen
        self.updateMap()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // called as soon as map stops moving.
        // self.updatePostsForVisibleRegion()
    }
}

extension PostMapViewController2: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        if self.awaitingZoomToCurrentLocation {
            if !locationAuthorized {
                self.awaitingZoomToCurrentLocation = false
                self.showAlertForDeniedPermissions(permissionType: Strings.LocationPermissionType)
            } else {
                if let location = locationManager.location {
                    self.zoomToLocation(location)
                } else {
                    self.locationManager.requestLocation()
                }
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.awaitingZoomToCurrentLocation, let location = locations.first {
            self.awaitingZoomToCurrentLocation = false
            self.zoomToLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
    }
}
extension PostMapViewController2: CreatePostControllerDelegate {
    func createPostController(_ controller: CreatePostViewController, didDeletePost post: Post) {
        self.updateMap(refreshCache: true)
    }
    
    func createPostController(_ controller: CreatePostViewController, didCreatePost post: Post) {
        
    }
    
    func createPostController(_ controller: CreatePostViewController, didUploadImageData: Data, forPost post: Post) {
        viewModel.addPost(post)
        self.updateMap(refreshCache: true)
        if let location = post.Location?.clLocation {
            self.zoomToLocation(location)
        }
    }
    
    func createPostController(_ controller: CreatePostViewController,
                              didBeginUploadForData: Data,
                              forPost post: Post, job: NetworkServiceJob?) {
    }
}
extension PostMapViewController2: PostListControllerDelegate {
    var canEditPosts: Bool {
        return true
    }
    
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath) {
        viewModel.removePost(post)
    }
}
extension PostMapViewController2: PostDetailDelegate {
    func postDetail(_ controller: PostDetailViewController, didUpdatePost post: Post) {
        self.updateMap(refreshCache: true)
    }
    
    func postDetail(_ controller: PostDetailViewController, didBlockUser user: User) {
        self.updateMap(refreshCache: true)
    }
    
    func postDetail(_ controller: PostDetailViewController, didDeletePost post: Post) {
        self.updateMap(refreshCache: true)
    }
}
