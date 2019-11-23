//
//  Array.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-15.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

extension Array {
    func itemAtIndex(_ index: Int) -> Element? {
        guard index < self.count else { return nil }
        return self[index]
    }
}
