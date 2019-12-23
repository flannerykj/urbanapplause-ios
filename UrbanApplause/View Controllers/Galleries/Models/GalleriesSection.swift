//
//  GalleriesSection.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum GalleriesSection: Int, CaseIterable {
    case myCollections = 0
    case other
    
    var title: String {
        switch self {
        case .myCollections:
            return "My collections"
        case .other:
            return "Other"
        }
    }
}
