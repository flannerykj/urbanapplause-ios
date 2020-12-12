//
//  Array.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-15.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public extension Array {
    subscript (safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
