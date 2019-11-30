//
//  PostMapViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit
/*
struct ZoomRangeBreakPoint {
    var threshold: Double
}

class ZoomRange {
    private let breakpoints: [Double] = [
        pow(Double(6.228531774600968), -6),
        // pow(Double(1.5258789364562093), -5),
        pow(Double(3.0517573685815012), -5),
        pow(Double(6.103514737163023), -5),
        0.00012207029474325965,
        0.0002441405894865236,
        0.0004882811789730343,
        // 0.0009765623579461544,
        0.0019531247158921029,
        // 0.0039062494317844802,
        0.0078124988635733545,
        0.015624997727142315,
        0.03124999545428463,
        0.06249999090863956,
        0.12499998181671673,
        1.366025127921254,
        0.24999996363343346,
        0.4999999272848635,
        0.9999998545157373
    ] // zoomed out to zoomed in
    
    var lastBreakpointIndex: Int = 0
    
    func didPassBreakpoint(_ zoomScale: Double) -> Bool {
        var nextBreakpointIndex: Int = 0
        for i in 0..<breakpoints.count {
            if zoomScale > breakpoints[i] {
                nextBreakpointIndex = i
            } else {
                break
            }
        }
        if nextBreakpointIndex != lastBreakpointIndex {
            lastBreakpointIndex = nextBreakpointIndex
            return true
        }
        return false
    }
    
    init() {}
} */
struct ProximityFilter {
    var target: CLLocationCoordinate2D
    var maxDistanceKm: CGFloat
}
struct GeoBoundsFilter {
    var neCoord: CLLocationCoordinate2D
    var swCoord: CLLocationCoordinate2D
}

class PostMapViewModel {
    // private var zoomRange = ZoomRange()
    
    private var timer: Timer?
    private var mainCoordinator: MainCoordinator
    private var lastLoadedClusters: [PostCluster] = []
    private var lastLoadedMapRect = MKMapRect()
    private var lastLoadedZoomScale: Double = 0
    
    private var currentMapRect: MKMapRect?
    private var currentMapPixelWidth: Double?
    
    var isLoading: Bool = false {
        didSet {
            didSetLoading?(isLoading)
        }
    }
    
    public var didSetLoading: ((Bool) -> Void)?
    public var onUpdateClusters: (([PostCluster]?, Bool) -> Void)?
    public var onError: ((Error) -> Void)?
    
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
    }
    public func getPostClusters(visibleMapRect: MKMapRect, mapPixelWidth: Double) {
        self.currentMapRect = visibleMapRect
        self.currentMapPixelWidth = mapPixelWidth
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.25,
                                     target: self,
                                     selector: #selector(self._getPostClusters(sender:)), userInfo: nil, repeats: false)
    }
    private func getZoomDidChange(_ firstValue: Double, _ secondValue: Double) -> Bool {
        let lastZoom = firstValue.rounded(toPlaces: 6)
        let currentZoom = secondValue.rounded(toPlaces: 6)
        // can't just compare Doubles. Since they are classes, double1 == double2 always returns false
        let didIncrease = currentZoom > lastZoom
        let didDecrease = currentZoom < lastZoom
        return didIncrease || didDecrease
    }

    @objc func _getPostClusters(sender: Timer) {
        guard let visibleMapRect = currentMapRect,
            let mapPixelWidth = currentMapPixelWidth else {
            return
        }
        let zoomScale = mapPixelWidth / visibleMapRect.size.width
        log.debug("zoom scale: \(zoomScale)")
        let zoomThresholdDidChange = self.getZoomDidChange(zoomScale, lastLoadedZoomScale)
        guard !isLoading && (!lastLoadedMapRect.contains(visibleMapRect) || zoomThresholdDidChange) else {
            self.onUpdateClusters?(nil, false)
            return
        }

        self.isLoading = true

        let clusterByProximity = getMarkerWidthInDegrees(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth)
        let filterForGeoBounds = getMapGeoBounds(visibleMapRect: visibleMapRect)
        _ = mainCoordinator.networkService.request(PrivateRouter.getPostClusters(postedAfter: nil,
                                                                             threshold: clusterByProximity,
                                                                             bounds: filterForGeoBounds)
        ) { [weak self] (result: UAResult<PostClustersContainer>) in
            guard self != nil else { return }
            DispatchQueue.main.async {
                self!.isLoading = false

                switch result {
                case .failure(let error):
                    self?.onError?(error)
                case .success(let clusterContainer):
                    if zoomThresholdDidChange {
                        // reload all annotations
                        
                        self!.onUpdateClusters?(clusterContainer.post_clusters, true)
                    } else {
                        // zoom threshold did not change, just frame
                        var clustersToAdd: [PostCluster] = []
                        // Add annotations that are outside intersection with lastLoadedRect
                        for cluster in clusterContainer.post_clusters {
                            let clusterCoordinate = CLLocationCoordinate2D(latitude: cluster.centroid.latitude,
                                                                       longitude: cluster.centroid.longitude)
                            if self!.lastLoadedMapRect.contains(MKMapPoint(clusterCoordinate)) {
                                // this cluster is within previously loaded area - skip
                                continue
                            }
                            clustersToAdd.append(cluster)
                        }
                        self!.onUpdateClusters?(clustersToAdd, false)
                    }
                    self!.lastLoadedMapRect = visibleMapRect
                    self!.lastLoadedClusters = clusterContainer.post_clusters
                    self!.lastLoadedZoomScale = zoomScale
                }
            }
        }
    }
    func getRegionForCluster(_ postCluster: PostCluster,
                             in mapRect: MKMapRect,
                             mapWidth: Double) -> MKCoordinateRegion {
        let coords: [CLLocationCoordinate2D] = postCluster.bounding_diagonal.coordinates.map { point in
            return CLLocationCoordinate2D(latitude: point[0], longitude: point[1])
        }
        let markerSpan = getMarkerWidthInDegrees(visibleMapRect: mapRect, mapPixelWidth: mapWidth)
        let latitudeDelta = CLLocationDegrees(abs(coords[0].latitude - coords[1].latitude) + markerSpan)
        let longitudeDelta = abs(coords[0].longitude - coords[1].longitude) + markerSpan
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta,
                                    longitudeDelta: longitudeDelta)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: postCluster.centroid.latitude,
                                                                 longitude: postCluster.centroid.longitude),
                                  span: span)
    }
    
    func getMarkerWidthInDegrees(visibleMapRect: MKMapRect, mapPixelWidth: Double) -> Double {
        let neMapPoint = MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.origin.y)
        let swMapPoint = MKMapPoint(x: visibleMapRect.origin.x, y: visibleMapRect.maxY)
        let neCoord = neMapPoint.coordinate
        let swCoord = swMapPoint.coordinate
        
        let mapWidthInDegrees = abs(neCoord.longitude - swCoord.longitude)
        let annotationWidthInPixels = AnnotationContentView.width
        
        return mapWidthInDegrees * Double(annotationWidthInPixels) / mapPixelWidth
    }
    
    func getMapGeoBounds(visibleMapRect: MKMapRect) -> GeoBoundsFilter {
        let neMapPoint = MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.origin.y)
        let swMapPoint = MKMapPoint(x: visibleMapRect.origin.x, y: visibleMapRect.maxY)
        let neCoord = neMapPoint.coordinate
        let swCoord = swMapPoint.coordinate
        return GeoBoundsFilter(neCoord: neCoord, swCoord: swCoord)
    }
    public func resetCache() {
        self.lastLoadedMapRect = MKMapRect()
        self.lastLoadedClusters = []
        self.lastLoadedZoomScale = 0
    }
}
