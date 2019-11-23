//
//  MapViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-15.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Eureka

public class MapViewController: UIViewController, TypedRowControllerType {
    var matchingItems: [MKMapItem] = []
    public var row: RowOf<CLPlacemark>!
    public var onDismissCallback: ((UIViewController) -> Void)?
    private lazy var searchController = UISearchController(searchResultsController: resultsTableController)
    var locationManager = CLLocationManager()
    var locationTrackingAuthorization: CLAuthorizationStatus?
    var markerReuseIdentifier = "postMarker"
    // Secondary search results table view.
    private lazy var resultsTableController = LocationSearchResultsController()
    
    lazy var mapView: MKMapView = { [unowned self] in
        let mapView = MKMapView(frame: self.view.frame)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: markerReuseIdentifier)
        return mapView
    }()

    lazy var useCurrentLocationButton = UIBarButtonItem(image: UIImage(systemName: "location"),
                                                        style: .plain,
                                                        target: self,
                                                        action: #selector(useCurrentLocation(_:)))
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // search setup
        resultsTableController.tableView.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        navigationItem.searchController = searchController
        
        // Make the search bar always visible.
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
        definesPresentationContext = true
        
        // navigation setup
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = useCurrentLocationButton
        
        // map setup
        view.addSubview(mapView)
        mapView.fill(view: self.view)
        
        let tapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressMap(sender:)))
        mapView.addGestureRecognizer(tapRecognizer)
        
       // add placemark for currently selected location
        if let placemark = row.value {
            setSelectedLocation(placemark: placemark)
        }
        // setupUserTrackingButtonAndScaleView()

        // location manager setup
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
    }

    convenience public init(_ callback: ((UIViewController) -> Void)?) {
        self.init(nibName: nil, bundle: nil)
        onDismissCallback = callback
    }
    
    private func setSelectedLocation(placemark: CLPlacemark) {
        log.debug("SETTING LOCATION")
        // dismiss search results
        searchController.isActive = false
        
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        
        guard let location = placemark.location else { log.error("invalid location"); return }
        // create new annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        // add annotation to map
        mapView.addAnnotation(annotation)
        
        // pan/zoom to new annotation
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        // set the value of the form field
        self.row.value = placemark
        
        // Get address for placemark
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error -> Void in
            guard error == nil else {
                log.error(error!)
                return
            }
            guard let placemarkWithInfo = placemarks?.first else { log.debug("No results for placemark"); return }
            self.row.value = placemarkWithInfo
            annotation.title = placemarkWithInfo.title
        })
    }
    
    @objc func useCurrentLocation(_: Any) {
        guard let authorization = self.locationTrackingAuthorization,
            (authorization == .authorizedWhenInUse || authorization == .authorizedAlways) else {
            showAlertForDeniedPermissions(permissionType: "location")
            return
        }
        if let location = locationManager.location {
            setSelectedLocation(placemark: MKPlacemark(coordinate: location.coordinate))
        }
    }
    
    @objc func didLongPressMap(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            let touchPoint = sender.location(in: mapView)
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
            let clCoordinate = CLLocationCoordinate2D(latitude: touchCoordinate.latitude,
                                                    longitude: touchCoordinate.longitude)
            let placemark = MKPlacemark(coordinate: clCoordinate, addressDictionary: [:])
            
            setSelectedLocation(placemark: placemark)
        }
    }
}
// MARK: - UISearchBarDelegate
extension MapViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // searchBar.resignFirstResponder()
    }
}

// MARK: - UISearchControllerDelegate
extension MapViewController: UISearchControllerDelegate {}

// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationTrackingAuthorization = status
    }
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error(error)
    }
}

protocol LocationSearchResultsDelegate: class {
    func locationSearchResults(didSelectPlacemark placemark: MKPlacemark)
}

extension MapViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let placemark = matchingItems[indexPath.row].placemark
        setSelectedLocation(placemark: placemark)
    }
}

extension MapViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            if error != nil {
                log.error(error.debugDescription)
            }
            guard let response = response else {
                return
            }
            self?.matchingItems = response.mapItems
            // Apply the filtered results to the search results table.
            if let resultsController = searchController.searchResultsController as? LocationSearchResultsController {
                resultsController.matchingItems = response.mapItems
                resultsController.tableView.reloadData()
            }
        }
    }
}

class LocationSearchResultsController: UITableViewController {
    var matchingItems = [MKMapItem]()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell",
                                                       for: indexPath) as? SubtitleTableViewCell else {
            fatalError()
        }
        let selectedItem = matchingItems[indexPath.row].placemark
        
        cell.textLabel?.text = selectedItem.name
        var addressComponents = [String]()
        if let locality = selectedItem.locality {
            addressComponents.append(locality)
        }
        if let subLocality = selectedItem.subLocality {
            addressComponents.append(subLocality)
        }
        if let administrativeArea = selectedItem.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        if let subLocality = selectedItem.subLocality {
            addressComponents.append(subLocality)
        }
        if let country = selectedItem.country {
            addressComponents.append(country)
        }
        let address = addressComponents.joined(separator: ", ")
        cell.detailTextLabel?.text = address
        return cell
    }
}
extension MapViewController: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: markerReuseIdentifier)
        annotationView?.annotation = annotation
        annotationView?.isDraggable = true
        return annotationView
    }
    
    // Make pins draggable
    public func mapView(_ mapView: MKMapView,
                        annotationView view: MKAnnotationView,
                        didChange newState: MKAnnotationView.DragState,
                        fromOldState oldState: MKAnnotationView.DragState) {
        switch newState {
        case .starting:
            view.dragState = .dragging
        case .ending, .canceling:
            view.dragState = .none
        default: break
        }
        if let newCoordinate = view.annotation?.coordinate {
            let placemark = MKPlacemark(coordinate: newCoordinate)
            setSelectedLocation(placemark: placemark)
        }
    }
}
class SubtitleTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
