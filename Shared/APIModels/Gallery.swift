//
//  Gallery.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

public enum Gallery: Equatable {
    case custom(Collection), visits, applause, posted
    
    public var id: Int {
        switch self {
        case .custom(let collection):
            return collection.id
        case .visits:
            return -1
        case .applause:
            return -2
        case .posted:
            return -3
        }
    }
    
    public var title: String {
        switch self {
        case .custom(let collection):
            return collection.title
        case .visits:
            return "Visited"
        case .applause:
            return "Applauded"
        case .posted:
            return "Posted"
        }
    }
    
    public var icon: UIImage? {
        switch self {
        case .visits:
            return UIImage(systemName: "eye")
        case .applause:
            return UIImage(named: "applause")
        default:
            return nil
        }
    }

    public static func == (lhs: Gallery, rhs: Gallery) -> Bool {
        switch (lhs, rhs) {
        case (.custom(let collectionLHS), .custom(let collectionRHS)):
            return collectionLHS.id == collectionRHS.id
        case (.visits, .visits):
            return true
        case (.applause, .applause):
            return true
        default:
            return false
        }
    }
}
