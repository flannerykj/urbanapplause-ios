//
//  PostMapViewModel2.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

struct ProximityFilter {
    var target: CLLocationCoordinate2D
    var maxDistanceKm: CGFloat
}
struct GeoBoundsFilter {
    var neCoord: CLLocationCoordinate2D
    var swCoord: CLLocationCoordinate2D
}

// 1. When the user moves the map, the controller requests updated data from the view model via `public func getPosts(_:)`.
// 2. The view model will either:
// a)


class PostMapViewModel2 {
    public var didSetLoading: ((Bool) -> Void)?
    public var onUpdateMarkers: (([MKAnnotation]?, Bool) -> Void)?
    public var onError: ((Error) -> Void)?
    
    private var timer: Timer?
    private var mainCoordinator: MainCoordinator
    
    private var requestedForceReload: Bool = false
    
    private var visibleClusters: [PostCluster]?
    private var visibleMapRect: MKMapRect?

    private var lastLoadedMapRect = MKMapRect()
    private var lastLoadedZoomScale: Double = 0
    private var loadedAllPostsForRect: MKMapRect?
    private var visibleMapPixelWidth: Double?
    
    var isLoading: Bool = false {
        didSet {
            didSetLoading?(isLoading)
        }
    }
    
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
    }
    public func requestMapData(visibleMapRect: MKMapRect, mapPixelWidth: Double, forceReload: Bool = false) {
        self.requestedForceReload = forceReload
        self.visibleMapRect = visibleMapRect
        self.visibleMapPixelWidth = mapPixelWidth
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.25,
                                     target: self,
                                     selector: #selector(self.fetchData(sender:)),
                                     userInfo: nil,
                                     repeats: false)
    }
    
    @objc func fetchData(sender: Timer) {
        guard let visibleMapRect = visibleMapRect,
            let mapPixelWidth = visibleMapPixelWidth else {
            return
        }
        let zoomScale = mapPixelWidth / visibleMapRect.size.width
        // Decide whether to get clusters or individual posts
        if shouldClusterPosts(zoomScale: zoomScale) {
            self.getAllPostClusters(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth)
        } else {
            self.getIndividualPosts(visibleMapRect: visibleMapRect)
        }
    }
    func getAllPostClusters(visibleMapRect: MKMapRect, mapPixelWidth: Double) {
        if self.visibleClusters != nil && !requestedForceReload {
            return
        }
        let clusterByProximity = getMarkerWidthInDegrees(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth) / 2
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
                    self?.visibleClusters = clusterContainer.post_clusters
                    self!.onUpdateMarkers?(clusterContainer.post_clusters, true)
                    self!.lastLoadedMapRect = visibleMapRect
                    self!.lastLoadedZoomScale = mapPixelWidth / visibleMapRect.size.width
                }
            }
        }
    }

    func getIndividualPosts(visibleMapRect: MKMapRect?) {
        log.debug("getting posts")
        self.visibleClusters = nil
        if let loadedRect = self.loadedAllPostsForRect, let nextRect = visibleMapRect {
            if loadedRect.contains(nextRect) {
                // self.onUpdateMarkers?(nil, false)
                return
            }
        }
        self.isLoading = true
        var filterForGeoBounds: GeoBoundsFilter?
        if let nextRect = visibleMapRect {
            filterForGeoBounds = getMapGeoBounds(visibleMapRect: nextRect)
        }

        let query = PostQuery(page: 0,
                            limit: 100,
                            userId: nil,
                            applaudedBy: nil,
                            artistId: nil,
                            search: nil,
                            collectionId: nil,
                            proximity: nil,
                            bounds: filterForGeoBounds,
                            include: [])
        _ = mainCoordinator.networkService.request(PrivateRouter.getPosts(query: query)
        ) { [weak self] (result: UAResult<PostsContainer>) in
            guard self != nil else { return }
            DispatchQueue.main.async {
                self!.isLoading = false
                switch result {
                case .failure(let error):
                    self?.onError?(error)
                case .success(let container):
                    self!.loadedAllPostsForRect = visibleMapRect
                    self!.lastLoadedMapRect = visibleMapRect ?? self!.lastLoadedMapRect
                    self!.onUpdateMarkers?(container.posts, true)
                }
            }
        }
    }
    func getRegionForCluster(_ postCluster: PostCluster,
                             mapBounds: CGRect) -> MKCoordinateRegion {
        let coords: [CLLocationCoordinate2D] = postCluster.bounding_diagonal.coordinates.map { point in
            return CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
        }
        let latitudeDelta = CLLocationDegrees(abs(coords[0].latitude - coords[1].latitude))
        let longitudeDelta = abs(coords[0].longitude - coords[1].longitude)
        let markerDegreesWidth = latitudeDelta * Double(AnnotationContentView.width) / Double(mapBounds.width)
        let markerDegreesHeight = longitudeDelta * Double(AnnotationContentView.height) / Double(mapBounds.height)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta + markerDegreesWidth,
                                    longitudeDelta: longitudeDelta + markerDegreesHeight)
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
        let markerWidthInDegrees = mapWidthInDegrees * Double(annotationWidthInPixels) / mapPixelWidth
        return markerWidthInDegrees
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
        self.visibleClusters = nil
        self.lastLoadedZoomScale = 0
    }

    private func isRectCovered(_ rect: CGRect, by rects: [CGRect]) -> Bool {
        
        
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
