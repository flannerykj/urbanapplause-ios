//
//  GalleriesSection.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

enum GalleriesSection: Int, CaseIterable {
    case collections = 0
    case other
    
    var title: String {
        switch self {
        case .collections:
            return Strings.MyGalleriesSectionTitle
        case .other:
            return Strings.OtherGalleriesSectionTitle
        }
    }
}
