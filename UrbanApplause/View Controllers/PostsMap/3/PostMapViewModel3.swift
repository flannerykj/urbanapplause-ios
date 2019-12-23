//
//  PostMapViewModel3.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

class PostMapViewModel3 {
    public var didSetLoading: ((Bool) -> Void)?
    public var onUpdateMarkers: (([MKAnnotation]?, Bool) -> Void)?
    public var onError: ((Error) -> Void)?
    
    private var mainCoordinator: MainCoordinator
    private var loadedPosts: [Post]?
    
    var isLoading: Bool = false {
        didSet {
            didSetLoading?(isLoading)
        }
    }
    
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
    }

    public func getIndividualPosts(forceReload: Bool = true) {
        if !forceReload, let cachedPosts = self.loadedPosts {
           self.onUpdateMarkers?(cachedPosts, true)
            return
        }
        self.isLoading = true
        let query = PostQuery(page: 0,
                            limit: 100,
                            userId: nil,
                            applaudedBy: nil,
                            artistId: nil,
                            search: nil,
                            collectionId: nil,
                            proximity: nil,
                            bounds: nil,
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
                    self!.loadedPosts = container.posts
                    self!.onUpdateMarkers?(container.posts, true)
                }
            }
        }
    }
    
    public func addPost(_ post: Post) {
        var cached = self.loadedPosts ?? []
        cached.append(post)
        self.loadedPosts = cached
        onUpdateMarkers?(cached, true)
    }
    public func removePost(_ post: Post) {
        var cached = self.loadedPosts ?? []
        cached.removeAll(where: { $0.id == post.id })
        self.loadedPosts = cached
        onUpdateMarkers?(cached, true)
    }
    public func resetCache() {
        self.loadedPosts = nil
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
    
    func isAtMaxZoom(visibleMapRect: MKMapRect, mapPixelWidth: Double) -> Bool {
        let zoomScale = mapPixelWidth / visibleMapRect.size.width // This number increases as you zoom in.
        let maxZoomScale: Double = 0.194138880976604 // This is the greatest zoom scale Map Kit lets you get to,
        // i.e. the most you can zoom in.
        return zoomScale >= maxZoomScale
    }
}
