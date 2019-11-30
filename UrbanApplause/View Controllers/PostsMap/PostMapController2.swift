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

class PostMapViewController2: UIViewController {
    var viewModel: PostMapViewModel2
    var mainCoordinator: MainCoordinator
    var needsUpdate: Bool = false {
        didSet {
            self.updateMap(refreshCache: true)
        }
    }
    lazy var scaleView: MKScaleView = MKScaleView(mapView: mapView)
    lazy var userLocationButton = IconButton(image: UIImage(systemName: "location"),
                                             activeImage: UIImage(systemName: "location.fill"),
                                             imageColor: .systemBlue,
                                             imageSize: CGSize(width: 32, height: 32),
                                             target: self,
                                             action: #selector(requestZoomToCurrentLocation(_:)))
    
    // Create a location manager to trigger user tracking
    var locationManager = CLLocationManager()
    var locationTrackingAuthorization: CLAuthorizationStatus?
    var requestedZoomToCurrentLocation: Bool = false
    
    init(viewModel: PostMapViewModel2, mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.onError = self.handleError
    }
    let activityIndicator = CircularLoader(frame: .zero)
    
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
        self.updateMap(refreshCache: true)
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
        mapView.fill(view: view)
        
        view.addSubview(userLocationButton)
        NSLayoutConstraint.activate([
            userLocationButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24),
            userLocationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        mapView.addSubview(loadingView)
        loadingView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor).isActive = true
        loadingView.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
        let backItem = UIBarButtonItem()
        backItem.title = "Map"
        navigationItem.backBarButtonItem = backItem

        viewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                self.loadingView.isHidden = !isLoading
            }
        }
        
        viewModel.onUpdateClusters = { clustersAdded, clearExistingClusters in
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
        mapView.register(PostGISClusterAnnotationView2.self,
                         forAnnotationViewWithReuseIdentifier: PostGISClusterAnnotationView2.reuseIdentifier)
        mapView.register(PostAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: PostAnnotationView.reuseIdentifier)
        return mapView
    }()
    
    @objc func tappedAnnotation(sender: UITapGestureRecognizer) {
        if let annotationView = sender.view as? PostGISClusterAnnotationView,
            let clusterAnnotation = annotationView.annotation as? PostCluster {
            if clusterAnnotation.count == 1 {
                let viewController = PostDetailViewController(postId: clusterAnnotation.cover_post_id,
                                                              post: nil,
                                                              mainCoordinator: mainCoordinator)
                
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                let region = viewModel.getRegionForCluster(clusterAnnotation,
                                                           in: self.mapView.visibleMapRect,
                                                           mapWidth: Double(self.mapView.bounds.width))
                mapView.setRegion(region, animated: true)
            }
        }
    }
    func handleError(_ error: Error) {
        log.error(error)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = self.view.frame
        updateMap()
        view.bringSubviewToFront(userLocationButton)
    }
    
    func updateMap(refreshCache: Bool = false) {
        if refreshCache {
            viewModel.resetCache()
        }
        log.debug("map visible rec: \(mapView.visibleMapRect)")
        viewModel.getPosts(visibleMapRect: mapView.visibleMapRect, mapPixelWidth: Double(mapView.bounds.width))
    }
    @objc func requestZoomToCurrentLocation(_: Any) {
        log.debug("requested zoom to current. status is : \(locationTrackingAuthorization)")
        if locationTrackingAuthorization == .denied {
            log.debug("status is denied")
            showAlertForDeniedPermissions(permissionType: "location")
        } else if let location = locationManager.location {
            self.zoomToLocation(location)
            return
        } else {
            requestedZoomToCurrentLocation = true
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestLocation()
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
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // exit if the annotation is the `MKUserLocation`
            return nil
        }
        if let clusterAnnotation = annotation as? PostCluster {
            guard let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PostGISClusterAnnotationView2.reuseIdentifier) as? PostGISClusterAnnotationView2 else {
                return nil
            }
            annotationView.annotation = clusterAnnotation
            let file: File = clusterAnnotation.cover_image_thumb ?? clusterAnnotation.cover_image
            annotationView.downloadJob = mainCoordinator.fileCache.getJobForFile(file)
            let gr = UITapGestureRecognizer(target: self, action: #selector(tappedAnnotation(sender:)))
            annotationView.addGestureRecognizer(gr)
            return annotationView
        } else if let postAnnotation = annotation as? Post {
            guard let annotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PostAnnotationView.reuseIdentifier) as? PostAnnotationView else {
                return nil
            }
            annotationView.annotation = postAnnotation
            if let file: File = postAnnotation.PostImages?.first?.thumbnail {
                annotationView.downloadJob = mainCoordinator.fileCache.getJobForFile(file)
            }
            let gr = UITapGestureRecognizer(target: self, action: #selector(tappedAnnotation(sender:)))
            annotationView.addGestureRecognizer(gr)
            return annotationView
        }
        return nil
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
        // userLocationButton.isHidden = !locationAuthorized
        log.debug("updated status: \(status)")
        self.locationTrackingAuthorization = status
        if !locationAuthorized, self.requestedZoomToCurrentLocation {
            self.requestedZoomToCurrentLocation = false
            self.showAlertForDeniedPermissions(permissionType: "location")
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if self.requestedZoomToCurrentLocation, let location = locations.first {
            self.requestedZoomToCurrentLocation = false
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
    }
    
    func didDeletePost(post: Post) {
        self.updateMap(refreshCache: true)
    }
}
