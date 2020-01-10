//
//  Filter.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

public protocol Filter {
    associatedtype ValueType
    func doesMatchItem(_ item: Post) -> Bool
}

open class PostFilter: Filter {
    public typealias ValueType = Post
    
    public func doesMatchItem(_ item: Post) -> Bool {
        fatalError("This should be overriden")
    }
}

open class PostUserFilter: PostFilter {
    public var selectedUser: User?
    
    override public func doesMatchItem(_ item: Post) -> Bool {
        guard let selectedUser = self.selectedUser else {
            return true // don't apply filter if no user selected
        }
        return item.User?.id == selectedUser.id
    }
}
public struct ProximityFilter {
    public var target: CLLocationCoordinate2D
    public var maxDistanceKm: CGFloat
    
    public init(target: CLLocationCoordinate2D, maxDistanceKm: CGFloat) {
        self.target = target
        self.maxDistanceKm = maxDistanceKm
    }
}
public struct GeoBoundsFilter {
    public var neCoord: CLLocationCoordinate2D
    public var swCoord: CLLocationCoordinate2D
    
    public init(neCoord: CLLocationCoordinate2D, swCoord: CLLocationCoordinate2D) {
        self.neCoord = neCoord
        self.swCoord = swCoord
    }
}
