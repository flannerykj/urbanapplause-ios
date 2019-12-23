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
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.fillWithinSafeArea(view: view)
        
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
        mapView.delegate = self
        mapView.register(PostGISClusterMKClusterAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: PostGISClusterMKClusterAnnotationView.reuseIdentifier)
        
        mapView.register(PostGISClusterAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: PostGISClusterAnnotationView.reuseIdentifier)
        
        mapView.register(PostMKClusterAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: PostMKClusterAnnotationView.reuseIdentifier)
        
        mapView.register(PostAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: PostAnnotationView.reuseIdentifier)
        return mapView
    }()
    
    @objc func tappedAnnotation(sender: UITapGestureRecognizer) {
        guard let annotationView = sender.view as? MKAnnotationView else { return }
        
        if let clusterAnnotation = annotationView.annotation as? PostCluster {
            if clusterAnnotation.count == 1 {
                let viewController = PostDetailViewController(postId: clusterAnnotation.cover_post_id,
                                                              post: nil,
                                                              mainCoordinator: mainCoordinator)
                
                navigationController?.pushViewController(viewController, animated: true)
            } else {
                let region = viewModel.getRegionForCluster(clusterAnnotation,
                                                           mapBounds: self.mapView.bounds)
                mapView.setRegion(region, animated: true)
            }
        } else if let annotation = annotationView.annotation as? MKClusterAnnotation,
            let members = annotation.memberAnnotations as? [Post] {
            self.mapView.showAnnotations(members, animated: true)
        } else if let post = annotationView.annotation as? Post {
            let viewController = PostDetailViewController(postId: post.id,
                                                          post: post,
                                                          mainCoordinator: mainCoordinator)
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    func handleError(_ error: Error) {
        log.error(error)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMap()
        view.bringSubviewToFront(userLocationButton)
    }
    
    func updateMap(refreshCache: Bool = false) {
        if refreshCache {
            viewModel.resetCache()
        }
        viewModel.requestMapData(visibleMapRect: mapView.visibleMapRect, mapPixelWidth: Double(mapView.bounds.width))
    }
    @objc func requestZoomToCurrentLocation(_: Any) {
        if locationTrackingAuthorization == .denied {
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
        log.debug("dequeing view for annotation: \(annotation.coordinate.latitude)")
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // exit if the annotation is the `MKUserLocation`
            return nil
        }
        var annotationView: MKAnnotationView?
        
        if let mkClusterAnnotation = annotation as? MKClusterAnnotation {
            if let clusterMembers = mkClusterAnnotation.memberAnnotations as? [PostCluster] {
                // clustered by mapkit and on backend - red
                guard let mkClusterAnnotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: PostGISClusterMKClusterAnnotationView.reuseIdentifier) as? PostGISClusterMKClusterAnnotationView else {
                    return nil
                }
                mkClusterAnnotationView.annotation = mkClusterAnnotation
                if let firstMember = clusterMembers.first {
                    let file: File = firstMember.cover_image_thumb ?? firstMember.cover_image
                    mkClusterAnnotationView.downloadJob = mainCoordinator.fileCache.getJobForFile(file)
                }
                annotationView = mkClusterAnnotationView
            } else if let postMembers = mkClusterAnnotation.memberAnnotations as? [Post] {
               // clustered by mapkit only - yellow
                guard let mkClusterAnnotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: PostMKClusterAnnotationView.reuseIdentifier) as? PostMKClusterAnnotationView else {
                    return nil
                }
                
                mkClusterAnnotationView.annotation = mkClusterAnnotation
                if let firstMember = postMembers.first, let firstImage = firstMember.PostImages?.first {
                    let file: File = firstImage.thumbnail ?? firstImage
                    mkClusterAnnotationView.downloadJob = mainCoordinator.fileCache.getJobForFile(file)
                }
                annotationView = mkClusterAnnotationView
            }
        } else if let postGISClusterAnnotation = annotation as? PostCluster {
            // clustered by backend only - orange
            guard let postGISClusterAnnotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PostGISClusterAnnotationView.reuseIdentifier) as? PostGISClusterAnnotationView else {
                return nil
            }
            postGISClusterAnnotationView.annotation = postGISClusterAnnotation
            let file: File = postGISClusterAnnotation.cover_image_thumb ?? postGISClusterAnnotation.cover_image
            postGISClusterAnnotationView.downloadJob = mainCoordinator.fileCache.getJobForFile(file)
            annotationView = postGISClusterAnnotationView
        } else if let postAnnotation = annotation as? Post {
            // no clustering - green
            guard let postAnnotationView = mapView.dequeueReusableAnnotationView(
                withIdentifier: PostAnnotationView.reuseIdentifier) as? PostAnnotationView else {
                return nil
            }
            postAnnotationView.annotation = postAnnotation
            if let file: File = postAnnotation.PostImages?.first?.thumbnail {
                postAnnotationView.downloadJob = mainCoordinator.fileCache.getJobForFile(file)
            }
            annotationView = postAnnotationView
        } else {
            log.debug("annotation of unknown type: \(annotation)")
        }
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(tappedAnnotation(sender:)))
        annotationView?.addGestureRecognizer(gr)
        return annotationView
    }
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        // called while user is moving the screen
        self.updateMap()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // called as soon as map stops moving.
        // self.updatePostsForVisibleRegion()
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        log.debug("did add views: \(views.count)")
    }
}

extension PostMapViewController2: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let locationAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        // userLocationButton.isHidden = !locationAuthorized
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
