//
//  PostMapViewModel2.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit
import Shared
import RxSwift

// 1. When the user moves the map, the controller requests updated data from the view model via `public func getPosts(_:)`.
// 2. The view model will either:
// a)


protocol MapDataStream {
    var isLoading: Observable<Bool> { get }
    var mapMarkers: Observable<[MKAnnotation]?> { get }
    var error: Observable<Error?> { get }
    
    func requestMapData(visibleMapRect: MKMapRect, mapPixelWidth: Double, forceReload: Bool)
    func getAllPostClusters(visibleMapRect: MKMapRect, mapPixelWidth: Double)
    func getRegionForClusters(_ postClusters: [PostCluster],
                              mapBounds: CGRect) -> MKCoordinateRegion?
    func getRegionForCluster(_ postCluster: PostCluster,
                             mapBounds: CGRect) -> MKCoordinateRegion?
    func isAtMaxZoom(visibleMapRect: MKMapRect, mapPixelWidth: Double) -> Bool
    func resetCache()
    func addPost(_ post: Post)
    func removePost(_ post: Post)
}


class PostMapViewModel2: MapDataStream {
    
    // MARK: - Private
    var mutableIsLoading: BehaviorSubject<Bool> = BehaviorSubject<Bool>(value: false)
    var mutableMapMarkers: BehaviorSubject<[MKAnnotation]?> = BehaviorSubject<[MKAnnotation]?>(value: nil)
    var mutableError: BehaviorSubject<Error?> = BehaviorSubject<Error?>(value: nil)

    enum RequestedMapContent {
        case posts, postClusters
    }

    private var didTransitionZoomBoundary: Bool = false
    private var timer: Timer?
    private var appContext: AppContext
    
    private var requestedForceReload: Bool = false
    
    private var visiblePosts: [Post]?
    private var visibleClusters: [PostCluster]?
    private var visibleMapRect: MKMapRect?

    private var lastLoadedClustersMapRect = MKMapRect()
    private var lastLoadedZoomScale: Double = 0
    private var loadedAllPostsForRect: MKMapRect?
    private var visibleMapPixelWidth: Double?
    private var lastRequestedMapContent: RequestedMapContent? = nil

    
    init(appContext: AppContext) {
        self.appContext = appContext
    }
    
    // MARK: - MapDataStream

    var isLoading: Observable<Bool> {
        return mutableIsLoading
    }
    
    var mapMarkers: Observable<[MKAnnotation]?> {
        return mutableMapMarkers
    }
    
    var error: Observable<Error?> {
        return mutableError
    }
    
    public func requestMapData(visibleMapRect: MKMapRect, mapPixelWidth: Double, forceReload: Bool) {
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
    
    func getAllPostClusters(visibleMapRect: MKMapRect, mapPixelWidth: Double) {
        if (try? mutableIsLoading.value()) ?? false && !requestedForceReload {
            return
        }
        if self.visibleClusters != nil
            && !requestedForceReload
            && lastLoadedClustersMapRect.contains(visibleMapRect)
            && !getZoomDidChange(mapPixelWidth / visibleMapRect.size.width, lastLoadedZoomScale)
            && lastRequestedMapContent == .postClusters {
            return
        }
        let clusterByProximity = getMarkerWidthInDegrees(visibleMapRect: visibleMapRect, mapPixelWidth: mapPixelWidth) / 2
        self.mutableIsLoading.onNext(true)
        self.lastRequestedMapContent = .postClusters
        let requestedMapRect = visibleMapRect.insetBy(dx: -(visibleMapRect.width/2), dy: -(visibleMapRect.height/3))
        let filterForGeoBounds = getMapGeoBounds(visibleMapRect: requestedMapRect)
        _ = appContext.networkService.request(PrivateRouter.getPostClusters(postedAfter: nil,
                                                                             threshold: clusterByProximity,
                                                                             bounds: filterForGeoBounds)
        ) { [weak self] (result: UAResult<PostClustersContainer>) in
            guard self != nil else { return }
            DispatchQueue.main.async {
                self!.mutableIsLoading.onNext(false)
                switch result {
                case .failure(let error):
                    self?.mutableError.onNext(error)
                case .success(let clusterContainer):
                    self?.visibleClusters = clusterContainer.post_clusters
                    self!.mutableMapMarkers.onNext(clusterContainer.post_clusters)
                    self!.lastLoadedClustersMapRect = requestedMapRect
                    self!.lastLoadedZoomScale = mapPixelWidth / visibleMapRect.size.width
                }
            }
        }
    }

    func getIndividualPosts(visibleMapRect: MKMapRect?) {
        self.visibleClusters = nil
        if let loadedRect = self.loadedAllPostsForRect,
            let nextRect = visibleMapRect,
            lastRequestedMapContent == .posts {
            
            if loadedRect.contains(nextRect) {
                return
            }
        }
        self.lastRequestedMapContent = .posts
        self.mutableIsLoading.onNext(true)
        var filterForGeoBounds: GeoBoundsFilter?
        
        if let nextRect = visibleMapRect {
            let requestRect = nextRect.insetBy(dx: -(nextRect.width/2), dy: -(nextRect.height/3))
            filterForGeoBounds = getMapGeoBounds(visibleMapRect: requestRect)
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
                            include: ["post_images"])
        _ = appContext.networkService.request(PrivateRouter.getPosts(query: query)
        ) { [weak self] (result: UAResult<PostsContainer>) in
            guard self != nil else { return }
            DispatchQueue.main.async {
                self!.mutableIsLoading.onNext(false)
                switch result {
                case .failure(let error):
                    self?.mutableError.onNext(error)
                case .success(let container):
                    self!.visiblePosts = container.posts
                    self!.loadedAllPostsForRect = visibleMapRect
                    self!.mutableMapMarkers.onNext(container.posts)
                }
            }
        }
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
        log.debug("get geo bounds for rect: \(visibleMapRect)")
        let neMapPoint = MKMapPoint(x: visibleMapRect.maxX, y: visibleMapRect.origin.y)
        let swMapPoint = MKMapPoint(x: visibleMapRect.origin.x, y: visibleMapRect.maxY)
        let neCoord = neMapPoint.coordinate
        let swCoord = swMapPoint.coordinate
        log.debug("neCoord: \(neCoord)")
        log.debug("swCoord: \(swCoord)")

        return GeoBoundsFilter(neCoord: neCoord, swCoord: swCoord)
    }
    public func resetCache() {
        self.lastLoadedClustersMapRect = MKMapRect()
        self.visibleClusters = nil
        self.lastLoadedZoomScale = 0
    }
    
    public func addPost(_ post: Post) {
        var cached = self.visiblePosts ?? []
        cached.append(post)
        self.visiblePosts = cached
        mutableMapMarkers.onNext(cached)
    }
    public func removePost(_ post: Post) {
        var cached = self.visiblePosts ?? []
        cached.removeAll(where: { $0.id == post.id })
        self.visiblePosts = cached
        mutableMapMarkers.onNext(cached)
    }
    
    func getZoomLevel(visibleMapRect: MKMapRect, mapPixelWidth: Double) -> Int {
        let maxZoom: Double = 20
        let zoomScale = visibleMapRect.size.width / Double(mapPixelWidth)
        let zoomExponent = log2(zoomScale)
        return Int(maxZoom - ceil(zoomExponent))
    }
    
    func isAtMaxZoom(visibleMapRect: MKMapRect, mapPixelWidth: Double) -> Bool {
        let zoomScale = mapPixelWidth / visibleMapRect.size.width // This number increases as you zoom in.
        let maxZoomScale: Double = 0.194138880976604 // This is the greatest zoom scale Map Kit lets you get to,
        // i.e. the most you can zoom in.
        return zoomScale >= maxZoomScale
    }
    private func isRectCovered(_ rect: CGRect, by rects: [CGRect]) -> Bool {
        if areRectanglesExactCover(of: rect, rectangles: rects) {
            return true
        }
        // need to find algorith to determine if set of rectangles completely covers another rect. 
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
}
