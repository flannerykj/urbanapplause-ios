//
//  PostSurfaceType.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public enum PostSurfaceType: String, CaseIterable {
    case wall = "Wall"
    case train = "Train"
    case truck = "Truck"
    case billboard = "Billboard"
    case streetSign = "Street sign"
    case pavement = "Pavement"
    case other = "Other"
}

extension PostSurfaceType: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}
