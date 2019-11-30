//
//  PostMapViewModel2.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

class PostMapViewModel2 {
    public var didSetLoading: ((Bool) -> Void)?
    public var onUpdateClusters: (([MKAnnotation]?, Bool) -> Void)?
    public var onError: ((Error) -> Void)?
    
    private var timer: Timer?
    private var mainCoordinator: MainCoordinator
    
    private var requestedForceReload: Bool = false
    private var allClusters: [PostCluster]?
    private var lastLoadedClusters: [PostCluster] = []
    private var lastLoadedMapRect = MKMapRect()
    private var lastLoadedZoomScale: Double = 0
    private var loadedAllPostsForRect: MKMapRect?
    private var visibleMapRect: MKMapRect?
    private var mapPixelWidth: Double?
    
    var isLoading: Bool = false {
        didSet {
            didSetLoading?(isLoading)
        }
    }
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
    }
    public func getPosts(visibleMapRect: MKMapRect, mapPixelWidth: Double, forceReload: Bool = false) {
        self.requestedForceReload = forceReload
        if let loadedRect = self.loadedAllPostsForRect {
            log.debug("loaded clusters: \(loadedRect)")
            log.debug("visible: \(visibleMapRect)")
            log.debug("loaded contains visible: \(loadedRect.contains(visibleMapRect))")
        }

        self.visibleMapRect = visibleMapRect
        self.mapPixelWidth = mapPixelWidth
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.25,
                                     target: self,
                                     selector: #selector(self._getPosts(sender:)),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    @objc func _getPosts(sender: Timer) {
        guard let visibleMapRect = visibleMapRect,
            let mapPixelWidth = mapPixelWidth else {
            return
        }
        let zoomScale = mapPixelWidth / visibleMapRect.size.width

        log.debug("zoom scale: \(zoomScale)")
        // Decide whether to get clusters or individual posts
        guard !isLoading else {
            self.onUpdateClusters?(nil, false)
            return
        }
        
        if shouldClusterPosts(zoomScale: zoomScale) {
            // self.getPostClusters(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth)
            self.getAllPostClusters(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth)
        } else {
            self.getIndividualPosts(visibleMapRect: visibleMapRect)
        }
    }
    func getAllPostClusters(visibleMapRect: MKMapRect, mapPixelWidth: Double) {
        if self.allClusters != nil && !requestedForceReload { return }
        let clusterByProximity = getMarkerWidthInDegrees(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth)
        self.isLoading = true
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
                    self?.allClusters = clusterContainer.post_clusters
                    self!.onUpdateClusters?(clusterContainer.post_clusters, false)
                    self!.lastLoadedMapRect = visibleMapRect
                    self!.lastLoadedClusters = clusterContainer.post_clusters
                    self!.lastLoadedZoomScale = mapPixelWidth / visibleMapRect.size.width
                }
            }
        }
    }
    func getPostClusters(visibleMapRect: MKMapRect, mapPixelWidth: Double) {
        let zoomScale = mapPixelWidth / visibleMapRect.size.width
        let zoomThresholdDidChange = self.getZoomDidChange(zoomScale, lastLoadedZoomScale)

        guard (!lastLoadedMapRect.contains(visibleMapRect) || zoomThresholdDidChange) else {
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
    func getIndividualPosts(visibleMapRect: MKMapRect) {
        if let loadedRect = self.loadedAllPostsForRect {
            log.debug("loaded rect: \(loadedRect)")
            log.debug("visible rect: \(visibleMapRect)")
            log.debug("loaded contains visible: \(loadedRect.contains(visibleMapRect))")
            if loadedRect.contains(visibleMapRect) {
                self.onUpdateClusters?(nil, false)
                return
            }
        }
        self.isLoading = true
        let filterForGeoBounds = getMapGeoBounds(visibleMapRect: visibleMapRect)

        _ = mainCoordinator.networkService.request(PrivateRouter.getPosts(page: 0,
                                                                          limit: 100,
                                                                          userId: nil,
                                                                          applaudedBy: nil,
                                                                          artistId: nil,
                                                                          search: nil,
                                                                          collectionId: nil,
                                                                          proximity: nil,
                                                                          bounds: filterForGeoBounds,
                                                                          include: [])
        ) { [weak self] (result: UAResult<PostsContainer>) in
            guard self != nil else { return }
            DispatchQueue.main.async {
                self!.isLoading = false
                switch result {
                case .failure(let error):
                    self?.onError?(error)
                case .success(let container):
                    self!.loadedAllPostsForRect = visibleMapRect
                    self!.onUpdateClusters?(container.posts, true)
                    self!.lastLoadedMapRect = visibleMapRect
                    // self!.lastLoadedClusters = clusterContainer.post_clusters
                    // self!.lastLoadedZoosmScale = zoomScale
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
        let annotationWidthInPixels = AnnotationContentView.width / 2
        
        return mapWidthInDegrees * Double(annotationWidthInPixels) / mapPixelWidth
    }
    private func getZoomDidChange(_ firstValue: Double, _ secondValue: Double) -> Bool {
        let lastZoom = firstValue.rounded(toPlaces: 6)
        let currentZoom = secondValue.rounded(toPlaces: 6)
        // can't just compare Doubles. Since they are classes, double1 == double2 always returns false
        let didIncrease = currentZoom > lastZoom
        let didDecrease = currentZoom < lastZoom
        return didIncrease || didDecrease
    }
    
    private func shouldClusterPosts(zoomScale: Double) -> Bool {
        log.debug("zoomScale: \(zoomScale)")
        if zoomScale > 0.0009765623579461887 {
            return false
        }
        return true
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
    
    
    
    
    
    private func isRectCovered(_ rect: CGRect, by rects: [CGRect]) -> Bool {
        // TODO
        
        return false
    }
    private func areRectanglesExactCover(of rect: CGRect, rectangles: [CGRect]) -> Bool {
        let boundingRect = getMinBoundingRect(of: rectangles + [rect])
        return boundingRect.area == rect.area
    }

    private func getMinBoundingRect(of rects: [CGRect]) -> CGRect {
        return rects.reduce(CGRect(), { acc, rect in
            return acc.union(rect)
        })
    }
}
