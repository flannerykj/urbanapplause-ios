//
//  TourMapViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2020-11-20.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Shared
import CoreLocation
import FloatingPanel

class TourMapViewController: UIViewController, FloatingPanelControllerDelegate {
    private let collection: Collection
    private let appContext: AppContext
    var fpc: FloatingPanelController!
    
    var awaitingZoomToCurrentLocation: Bool = false
    // Create a location manager to trigger user tracking
    var locationManager = CLLocationManager()
    var requestedZoomToCurrentLocation: Bool = false
    
    init(collection: Collection, appContext: AppContext) {
        self.collection = collection
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = collection.title
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fpc.removeFromParent()
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
        
        updateMapMarkers()
        
        presentBottomSheet()
       
    }
    
    // MARK: - FloatingPanelControllerDelegate
 
    
    func presentBottomSheet() {
        fpc = FloatingPanelController()
        fpc.delegate = self
        let contentVC = TourInfoViewController(collection: collection, appContext: appContext)
        fpc.set(contentViewController: contentVC)
        fpc.track(scrollView: contentVC.tableView)
        fpc.addPanel(toParent: self)
    }
    
    private func updateMapMarkers() {
        self.mapView.removeAnnotations(self.mapView.annotations)
        if let posts = collection.Posts {
            self.mapView.addAnnotations(posts)
        }
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
                if isAtMaxZoom(visibleMapRect: mapView.visibleMapRect,
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
                let region = self.getRegionForClusters(members, mapBounds: self.mapView.bounds) {
                self.mapView.setRegion(region,
                                       animated: true)
            }
        } else if let post = annotationView.annotation as? Post {
            showDetailForPostWithID(post.id, post: post, thumbImage: thumbImage)
        } else if let postCluster = annotationView.annotation as? PostCluster {
            if postCluster.count == 1 {
                showDetailForPostWithID(postCluster.cover_post_id, post: nil, thumbImage: thumbImage)
            } else if let region = getRegionForCluster(postCluster, mapBounds: self.mapView.bounds) {
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
    
    @objc func longPressedMap(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            let touchPoint = sender.location(in: self.mapView)
            let touchCoordinate = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let placemark = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: touchCoordinate.latitude,
                                                                           longitude: touchCoordinate.longitude),
                                        addressDictionary: [:])
            
//            let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//            let addPost = UIAlertAction(title: Strings.AddPostHereButtonTitle, style: .default, handler: { _ in
//                self.addNewPost(sender: self.mapView, at: placemark)
//            })
//
//            let cancelAction = UIAlertAction(title: Strings.CancelButtonTitle, style: .cancel, handler: nil)
//            ac.addAction(addPost)
//            ac.addAction(cancelAction)
//            ac.popoverPresentationController?.sourceView = self.mapView
//            ac.popoverPresentationController?.sourceRect = CGRect(x: touchPoint.x, y: touchPoint.y, width: 0, height: 0)
//            present(ac, animated: true, completion: nil)
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
    
    func isAtMaxZoom(visibleMapRect: MKMapRect, mapPixelWidth: Double) -> Bool {
        let zoomScale = mapPixelWidth / visibleMapRect.size.width // This number increases as you zoom in.
        let maxZoomScale: Double = 0.194138880976604 // This is the greatest zoom scale Map Kit lets you get to,
        // i.e. the most you can zoom in.
        return zoomScale >= maxZoomScale
    }
    
    func getRegionForCluster(_ postCluster: PostCluster,
                             mapBounds: CGRect) -> MKCoordinateRegion? {
        let coords: [CLLocationCoordinate2D] = postCluster.bounding_diagonal.coordinates.map { point in
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
        let latitudeDelta = CLLocationDegrees(abs(coords[0].latitude - coords[1].latitude))
        let longitudeDelta = abs(coords[0].longitude - coords[1].longitude)
        let markerDegreesWidth = longitudeDelta * Double(AnnotationContentView.width) / Double(mapBounds.width)
        let markerDegreesHeight = latitudeDelta * Double(AnnotationContentView.height) / Double(mapBounds.height)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta + markerDegreesHeight*2,
                                    longitudeDelta: longitudeDelta + markerDegreesWidth*2)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: postCluster.centroid.latitude,
                                                                 longitude: postCluster.centroid.longitude),
                                  span: span)
    }
    
    func getRegionForClusters(_ postClusters: [PostCluster],
                              mapBounds: CGRect) -> MKCoordinateRegion? {
        guard postClusters.count > 0 else { return nil }
        let coords: [CLLocationCoordinate2D] = postClusters.reduce([], {acc, cluster in
            return  acc + cluster.bounding_diagonal.coordinates.map { point in
                CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
            }
        })
        let minLng = coords.map { $0.longitude }.min()!
        let maxLng = coords.map { $0.longitude }.max()!
        let minLat = coords.map { $0.latitude }.min()!
        let maxLat = coords.map { $0.latitude }.max()!
        
        let centerLat = (maxLat - minLat)/2
        let centerLng = (maxLng - minLng)/2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        let latitudeDelta = abs(maxLat - minLat)
        let longitudeDelta = abs(maxLng - minLng)
        let markerDegreesWidth = latitudeDelta * Double(AnnotationContentView.width) / Double(mapBounds.width)
        let markerDegreesHeight = longitudeDelta * Double(AnnotationContentView.height) / Double(mapBounds.height)
        let padding = markerDegreesWidth * 0.2
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta + markerDegreesHeight + padding*2,
                                    longitudeDelta: longitudeDelta + markerDegreesWidth + padding*2)
        return MKCoordinateRegion(center: center, span: span)
    }
    
}

extension TourMapViewController: MKMapViewDelegate {
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
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // called as soon as map stops moving.
        // self.updatePostsForVisibleRegion()
    }
}

extension TourMapViewController: CLLocationManagerDelegate {
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

extension TourMapViewController: PostDetailDelegate {
    func postDetail(_ controller: PostDetailViewController, didUpdatePost post: Post) {
        
    }
    
    func postDetail(_ controller: PostDetailViewController, didBlockUser user: User) {
        
    }
    
    func postDetail(_ controller: PostDetailViewController, didDeletePost post: Post) {
        
    }
    
    
}

extension TourMapViewController: PostListControllerDelegate {
    var canEditPosts: Bool {
        return false
    }
    
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath) {
        
    }
    
    
}
