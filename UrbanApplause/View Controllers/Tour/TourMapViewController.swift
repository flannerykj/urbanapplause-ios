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
import Combine

class TourMapViewController: UIViewController, FloatingPanelControllerDelegate {
    
    private let collection: Collection
    private let appContext: AppContext
    private let viewModel: TourMapDataStreaming
    private var cancellables = Set<AnyCancellable>()
    var fpc: FloatingPanelController!
    
    var awaitingZoomToCurrentLocation: Bool = false
    // Create a location manager to trigger user tracking
    var locationManager = CLLocationManager()
    var requestedZoomToCurrentLocation: Bool = false
    
    init(collection: Collection, appContext: AppContext) {
        self.collection = collection
        self.appContext = appContext
        self.viewModel = TourMapDataStream(appContext: appContext, collection: collection)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "\(collection.title) Tour"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fpc.removeFromParent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
        
        view.backgroundColor = UIColor.systemBackground
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
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
        mapView.addGestureRecognizer(gr)

        subscribeToDataStream()
        viewModel.fetchPosts()
        presentBottomSheet()
    }
    
    // MARK: - FloatingPanelControllerDelegate
    func floatingPanelDidMove(_ fpc: FloatingPanelController) {
        switch fpc.state {
        case .tip:
            viewModel.annotationsStream
                .first()
                .sink(receiveValue: { viewModels in
                    // reset map zoom
                    self.setMapRegion(for: viewModels.map { $0.post }, mapBounds: self.mapView.bounds)
                })
                .store(in: &cancellables)
        default:
            break
        }
    }
    
    func presentBottomSheet() {
        fpc = FloatingPanelController()
        let layout = TourFloatingPanelLayout()
        fpc.layout = layout
        fpc.delegate = self
        let contentVC = TourInfoViewController(tourDataStream: viewModel)
        fpc.set(contentViewController: contentVC)
        fpc.track(scrollView: contentVC.tableView)
        fpc.addPanel(toParent: self)
    }
    
    private func setMapRegion(for annotations: [MKAnnotation], mapBounds: CGRect, insets: UIEdgeInsets = .zero) {
        if let region = self.getRegionForPosts(annotations, mapBounds: mapBounds, insets: insets) {
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    private func subscribeToDataStream() {
        viewModel.annotationsStream
            .sink(receiveValue: { viewModels in
                DispatchQueue.main.async {
                    self.mapView.removeAnnotations(self.mapView.annotations)
                    self.mapView.addAnnotations(viewModels.map { $0.post })
                    self.setMapRegion(for: viewModels.map { $0.post }, mapBounds: self.mapView.bounds)
                    // self.updateRouteLine(for: viewModels.map { $0.post })
                }
            })
            .store(in: &cancellables)
        
        viewModel.selectedAnnotationIndex
            .scan( [ [],[] ] ) { seed, newValue in
                return [seed[1], newValue]
                }
            .combineLatest(viewModel.annotationsStream)
            .sink { indices, viewModels in
                let previousSelectedIndex = indices[0] as? Int
                let currentSelectedIndex = indices[1] as? Int
                
                let annotations = viewModels.map { $0.post }
            if let i = currentSelectedIndex {
                self.fpc.move(to: .half, animated: true)
                self.mapView.selectAnnotation(annotations[i], animated: true)
                
                if let fpcContentBounds = self.fpc.contentViewController?.view.bounds {
                    self.setMapRegion(for: [annotations[i]], mapBounds: self.mapView.bounds, insets: UIEdgeInsets(top: 0, left: 0, bottom: fpcContentBounds.height, right: 0))
                }
            } else {
                self.setMapRegion(for: annotations, mapBounds: self.mapView.bounds)
            }
            if let i = previousSelectedIndex {
                self.mapView.deselectAnnotation(annotations[i], animated: true)
            }
        }
        .store(in: &cancellables)
    }
    
    @objc func didTapMap(_ sender: UITapGestureRecognizer) {
        viewModel.annotationsStream
            .first()
            .sink { viewModels in
                self.fpc.move(to: .tip, animated: true, completion: {
                    self.viewModel.setSelectedPostIndex(nil)
                    self.setMapRegion(for: viewModels.map { $0.post }, mapBounds: self.mapView.bounds)
                })
            }
            .store(in: &cancellables)
    }
    
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView(frame: self.view.frame)
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.layoutMargins = UIEdgeInsets(top: AnnotationContentView.height, left: AnnotationContentView.width/2, bottom: 0, right: AnnotationContentView.width/2)
        mapView.register(PostAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        mapView.register(PostMKClusterAnnotationView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        return mapView
    }()
    
    private func updateRouteLine(for annotations: [MKAnnotation]) {
        guard var startingCoordinates = viewModel.startingPoint?.coordinate else { return }
    
        for annotation in annotations {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingCoordinates))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: annotation.coordinate))
            request.transportType = .walking
            let directions = MKDirections(request: request)
            directions.calculate(completionHandler: { [weak self] response, error in
                if let route = response?.routes.first {
                    self?.mapView.addOverlay(route.polyline)
                    self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                }
            })
            startingCoordinates = annotation.coordinate
        }
    }
    
    @objc func tappedAnnotation(sender: UITapGestureRecognizer) {
        guard let annotationView = sender.view as? MKAnnotationView else { return }

        if let post = annotationView.annotation as? WaypointViewModel {
            viewModel.annotationsStream
                .first()
                .sink { annotations in
                
                    if let selectedIndex = annotations.firstIndex(of: post) {
                        self.viewModel.setSelectedPostIndex(selectedIndex)
                    } else {
                        print("couldn't find annotation to match post")
                    }
                }
                .store(in: &cancellables)
            
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
    
    func getRegionForPosts(_ posts: [MKAnnotation],
                             mapBounds: CGRect,
                             insets: UIEdgeInsets = .zero) -> MKCoordinateRegion? {
        guard mapBounds.height > 0, mapBounds.width > 0 else { return nil }
        let coords: [CLLocationCoordinate2D] = posts.map { $0.coordinate }
        
        guard let minLng = coords.map({ $0.longitude }).min(),
              let maxLng = coords.map({ $0.longitude }).max(),
              let minLat = coords.map({ $0.latitude }).min(),
              let maxLat = coords.map({ $0.latitude }).max() else {
            return nil
        }
        let maxZoom: CLLocationDegrees = 0.003
        let latitudeDelta: CLLocationDegrees = posts.count > 1 ? abs(maxLat - minLat) : maxZoom
        let longitudeDelta: CLLocationDegrees = posts.count > 1 ?  abs(maxLng - minLng) : maxZoom
        
        let markerDegreesWidth = latitudeDelta * Double(AnnotationContentView.width) / Double(mapBounds.width)
        let markerDegreesHeight = longitudeDelta * Double(AnnotationContentView.height) / Double(mapBounds.height)
        
        let bottomInsetsInDegrees = latitudeDelta * Double(insets.bottom) / Double(mapBounds.height)
        let centerLat = minLat + (maxLat - minLat)/2 - bottomInsetsInDegrees/2
        let centerLng = minLng + (maxLng - minLng)/2
        
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLng)
        
        let padding = markerDegreesWidth * 0.2
    
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta + markerDegreesHeight + padding*2,
                                    longitudeDelta: longitudeDelta + markerDegreesWidth + padding*2)
        return MKCoordinateRegion(center: center, span: span)
    }  
}

extension TourMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let viewModel = annotation as? WaypointViewModel {
            return PostAnnotationView(annotation: viewModel.post, reuseIdentifier: PostAnnotationView.reuseIdentifier)
        }
        log.debug("returning nil for annotation: \(annotation)")
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            let gr = UITapGestureRecognizer(target: self, action: #selector(tappedAnnotation(sender:)))
            view.addGestureRecognizer(gr)
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
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {}
    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
//        renderer.strokeColor = UIColor.blue
//
//        return renderer
//    }
//
    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
        
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
                    if awaitingZoomToCurrentLocation {
                        self.zoomToLocation(location)
                        self.awaitingZoomToCurrentLocation = false
                    }
                    self.viewModel.updateStartingPoint(location)
                } else {
                    self.locationManager.requestLocation()
                }
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            if self.awaitingZoomToCurrentLocation {
                self.awaitingZoomToCurrentLocation = false
                self.zoomToLocation(location)
            }
            self.viewModel.updateStartingPoint(location)
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
class TourFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .tip
    var anchors: [FloatingPanelState: FloatingPanelLayoutAnchoring] {
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 16.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.5, edge: .bottom, referenceGuide: .safeArea),
            .tip: FloatingPanelLayoutAnchor(absoluteInset: 100.0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }

}
