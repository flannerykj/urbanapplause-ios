//
//  Result.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

enum UAResult<T> {
    case success(T), failure(UAError)

    func get() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}
