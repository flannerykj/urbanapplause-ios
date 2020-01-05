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
import UrbanApplauseShared

class PostMapViewController2: UIViewController {
    var viewModel: PostMapViewModel2
    var mainCoordinator: MainCoordinator
    var needsUpdate: Bool = false {
        didSet {
            self.updateMap(refreshCache: true)
        }
    }
    var awaitingZoomToCurrentLocation: Bool = false

    lazy var scaleView: MKScaleView = MKScaleView(mapView: mapView)
    
    // Create a location manager to trigger user tracking
    var locationManager = CLLocationManager()
    var requestedZoomToCurrentLocation: Bool = false
    
    init(viewModel: PostMapViewModel2, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.onError = self.handleError
    }
    let activityIndicator = CircularLoader()
    
    lazy var loadingView: UIView = {
        let view = UIView()
        activityIndicator.heightAnchor.constraint(equalToConstant: 24).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 24).isActive = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.tintColor = UIColor.systemPink
        activityIndicator.animate()
        // activityIndicator.color = UIColor.systemPink
        // view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layoutMargins = StyleConstants.defaultPaddingInsets
        view.addSubview(activityIndicator)
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        activityIndicator.fillWithinMargins(view: view)
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let username = self.mainCoordinator.store.user.data?.username {
            navigationItem.title = "Welcome, \(username)"
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.fillWithinSafeArea(view: view)

        mapView.addSubview(loadingView)
        loadingView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor).isActive = true
        loadingView.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
        let backItem = UIBarButtonItem()
        backItem.title = "Map"
        navigationItem.backBarButtonItem = backItem
        
        let locationButton = UIBarButtonItem(image: UIImage(systemName: "location"),
                                             style: .plain,
                                             target: self,
                                             action: #selector(requestZoomToCurrentLocation(_:)))
        
        navigationItem.rightBarButtonItem = locationButton

        viewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                self.loadingView.isHidden = !isLoading
            }
        }
        
        viewModel.onUpdateMarkers = { clustersAdded, clearExistingClusters in
            DispatchQueue.main.async {
                if clearExistingClusters {
                    log.debug("clear existing")
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }
                if let clusters = clustersAdded {
                    log.debug("add clusters: \(clustersAdded)")
                    self.mapView.addAnnotations(clusters)
                    // self.mapView.showAnnotations(clusters, animated: true)
                    log.debug("map annotations: \(self.mapView.annotations)")
                }
            }
        }
                
        let gr = UILongPressGestureRecognizer(target: self, action: #selector(longPressedMap(sender:)))
        mapView.addGestureRecognizer(gr)
    }
    
    @objc func longPressedMap(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            let touchPoint = sender.location(in: self.mapView)
            let touchCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: touchCoordinate.latitude,
                                                                           longitude: touchCoordinate.longitude),
                                        addressDictionary: [:])
            
            let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let addPost = UIAlertAction(title: "Add a post here", style: .default, handler: { _ in
                self.addNewPost(at: placemark)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            ac.addAction(addPost)
            ac.addAction(cancelAction)
            ac.popoverPresentationController?.sourceView = self.mapView
            ac.popoverPresentationController?.sourceRect = CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0)
            present(ac, animated: true, completion: nil)
        }
    }
    
    func addNewPost(at placemark: CLPlacemark?) {
        let vc = NewPostViewController(placemark: placemark, mainCoordinator: self.mainCoordinator)
        vc.delegate = self
        let nav = UINavigationController(rootViewController: vc)
        nav.isModalInPresentation = true
        nav.presentationController?.delegate = self
        self.present(nav, animated: true, completion: {})
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
                    
                    let wallViewModel = StaticPostListViewModel(posts: members, mainCoordinator: mainCoordinator)
                    let wallController = PostListViewController(viewModel: wallViewModel,
                                                                mainCoordinator: mainCoordinator)
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
                                                      mainCoordinator: mainCoordinator)
        navigationController?.pushViewController(viewController, animated: true)
    }
    func handleError(_ error: Error) {
        log.error(error)
        let message = (error as? UAError)?.userMessage ?? error.localizedDescription
        showAlert(message: message)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMap()
    }
    
    func updateMap(refreshCache: Bool = false) {
        if refreshCache {
            viewModel.resetCache()
        }
        viewModel.requestMapData(visibleMapRect: mapView.visibleMapRect, mapPixelWidth: Double(mapView.bounds.width))
    }
    @objc func requestZoomToCurrentLocation(_: Any) {
        guard CLLocationManager.locationServicesEnabled() else {
            showAlert(message: "Please enable location services under Settings.")
            return
        }
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            awaitingZoomToCurrentLocation = true
        case .restricted, .denied:
            showAlertForDeniedPermissions(permissionType: "location")
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
                annotationView.fileCache = mainCoordinator.fileCache
            }
            if let annotationView = view as? PostMKClusterAnnotationView {
                annotationView.fileCache = mainCoordinator.fileCache
            }
            if let annotationView = view as? PostAnnotationView {
                annotationView.fileCache = mainCoordinator.fileCache
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
                self.showAlertForDeniedPermissions(permissionType: "location")
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
extension PostMapViewController2: PostFormDelegate {
    func didCreatePost(post: Post) {
        self.updateMap(refreshCache: true)
        if let location = post.Location?.clLocation {
            self.zoomToLocation(location)
        }
    }
    
    func didDeletePost(post: Post) {
        self.updateMap(refreshCache: true)
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
