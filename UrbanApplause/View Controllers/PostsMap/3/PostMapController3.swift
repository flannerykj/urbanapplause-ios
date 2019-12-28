//
//  PostMapController3.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class PostMapViewController3: UIViewController {
    var viewModel: PostMapViewModel3
    var mainCoordinator: MainCoordinator
    var needsUpdate: Bool = false {
        didSet {
            if needsUpdate {
                viewModel.getIndividualPosts(forceReload: true)
            }
        }
    }

    lazy var scaleView: MKScaleView = MKScaleView(mapView: mapView)
    
    // Create a location manager to trigger user tracking
    var locationManager = CLLocationManager()
    var awaitingZoomToCurrentLocation: Bool = false
    
    init(viewModel: PostMapViewModel3, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.onError = self.handleError
    }
    
    let activityIndicator = CircularLoader()
    
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
        
        mapView.addSubview(activityIndicator)
        mapView.showsUserLocation = true
        activityIndicator.centerXAnchor.constraint(equalTo: mapView.centerXAnchor).isActive = true
        activityIndicator.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor,
                                               constant: 24).isActive = true
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
                if isLoading {
                    self.activityIndicator.showAndAnimate()
                } else {
                    self.activityIndicator.hide()
                }
            }
        }
        
        viewModel.onUpdateMarkers = { clustersAdded, clearExistingClusters in
            DispatchQueue.main.async {
                if clearExistingClusters {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                }
                if let clusters = clustersAdded {
                    self.mapView.addAnnotations(clusters)
                }
            }
        }
        
        let gr = UILongPressGestureRecognizer(target: self, action: #selector(longPressedMap(sender:)))
        mapView.addGestureRecognizer(gr)
        
        self.viewModel.getIndividualPosts()
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
        mapView.delegate = self
        mapView.register(PostAnnotationView3.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        mapView.register(PostClusterAnnotationView3.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        return mapView
    }()
    
    @objc func tappedAnnotation(sender: UITapGestureRecognizer) {
        guard let annotationView = sender.view as? MKAnnotationView else { return }
        
        if let annotation = annotationView.annotation as? MKClusterAnnotation,
            let members = annotation.memberAnnotations as? [Post] {
            
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
        } else if let post = annotationView.annotation as? Post {
            let viewController = PostDetailViewController(postId: post.id,
                                                          post: post,
                                                          mainCoordinator: mainCoordinator)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    func handleError(_ error: Error) {
        // DEV
        showAlert(message: error.localizedDescription)
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
        self.awaitingZoomToCurrentLocation = false
        let region = MKCoordinateRegion(center: location.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
    }
}

extension PostMapViewController3: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard (annotation as? Post) != nil else { return nil }
        return PostAnnotationView3(annotation: annotation, reuseIdentifier: PostAnnotationView3.reuseIdentifier)
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        
        for view in views {
            let gr = UITapGestureRecognizer(target: self, action: #selector(tappedAnnotation(sender:)))
            view.addGestureRecognizer(gr)
            
            if let annotationView = view as? PostAnnotationView3 {
                annotationView.fileCache = mainCoordinator.fileCache
            }
            if let annotationView = view as? PostClusterAnnotationView3 {
                annotationView.fileCache = mainCoordinator.fileCache
            }
        }
        
    }
}

extension PostMapViewController3: CLLocationManagerDelegate {
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
extension PostMapViewController3: PostFormDelegate {
    func didCreatePost(post: Post) {
        viewModel.addPost(post)
    }
    
    func didDeletePost(post: Post) {
        viewModel.removePost(post)
    }
}
extension PostMapViewController3: PostListControllerDelegate {
    var canEditPosts: Bool {
        return true
    }
    
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath) {
        viewModel.removePost(post)
    }
}
