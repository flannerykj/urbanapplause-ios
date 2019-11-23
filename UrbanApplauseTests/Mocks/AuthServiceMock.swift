//
//  AuthServiceMock.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
@testable import UrbanApplause

class AuthServiceMock: AuthService {
    var mockCurrentDate: Date
    
    init(mockCurrentDate: Date = Date(), keychainService: KeychainService) {
        self.mockCurrentDate = mockCurrentDate
        super.init(keychainService: keychainService)
    }
    override var currentDate: Date {
        return mockCurrentDate
    }
}
