//
//  AuthServiceTests.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import XCTest

@testable import UrbanApplause

class AuthServiceTests: BaseTestCase {
    var keychainService: KeychainServiceMock!
    var authService: AuthServiceMock!
    var authResponse: AuthResponse!
    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
    lazy var currentDate = dateFormatter.date(from: "2019-11-06")!
    // swiftlint:disable:next line_length
    let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5ODUzNGYxMy0xNzg1LTRkNzItOTNmOC02NmQ1OWE3MTgwMTgiLCJyb2xlIjoidXNlciIsImVtYWlsIjoiZmxhbm5qQGdtYWlsLmNvbSIsImlhdCI6MTU3Mzc3NzQ5MSwiZXhwIjoxNTczOTUwMjkxLCJqdGkiOiIzNDNlNTM4ZS04NGZiLTRlZmItODY4OS00M2IzN2I3MmU3MGYifQ.SNNMBZ5YuufbQljNOi1R3syoUjUNSvsLBmzNjFNCevU"
   // swiftlint:disable:next line_length
    let expiredToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiMWRmZGQ4NC1lYmE0LTRlOWItOWM4OS1iNTE1ZDE1OTMzNDQiLCJyb2xlIjoidXNlciIsImVtYWlsIjoiRmxhbm5qQGdtYWlsLmNvbSIsImlhdCI6MTU3MjgxODUwMywiZXhwIjoxNTcyOTkxMzAzLCJqdGkiOiJjMTVhZTYwMC0xODgyLTQzZTgtYmVkNi02OGYzMDAxNjdjZDEifQ.G4FOh9fRyOcoR9tCZs92gCdZMAsBXG5k90NkImWAhvw"
    
    override func setUp() {
        // Create autb service with empty keychain
        self.keychainService = KeychainServiceMock()
        self.authService = AuthServiceMock(mockCurrentDate: currentDate, keychainService: self.keychainService)
        
        // Create sample auth response user (but don't load to keychain)
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "auth_user", withExtension: "json") else {
            XCTFail("Missing file: auth_user.json")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("couldnt get data")
        }
        let decoder = JSONDecoder()
        do {
            self.authResponse = try! decoder.decode(AuthResponse.self, from: data)
        } catch {
            
        }
    }
    
    override func tearDown() {
        keychainService = nil
        authService = nil
    }
    
    func testIsNotAuthenticatedWithEmptyKeychain() {
        self.keychainService = KeychainServiceMock()
        self.authService = AuthServiceMock(keychainService: keychainService)
        XCTAssertFalse(self.authService.isAuthenticated,
                       "Auth service with nothing saved not return isAuthenticated be true")
    }
    
    func testIsNotAuthenticatedWithExpiredToken() {
        do {
            try keychainService.save(item: AuthResponse(access_token: expiredToken,
                                                        refresh_token: nil, user: nil),
                                     to: KeychainItem.tokens.userAccount)
        } catch {
            XCTFail("Threw error saving to keychain")
        }
        XCTAssertFalse(self.authService.isAuthenticated,
                       "Should not be authenticated with invalid token")
    }
    func testIsAuthenticatedWithValidToken() {
        do {
            try keychainService.save(item: AuthResponse(access_token: validToken,
                                                        refresh_token: nil, user: nil),
                                     to: KeychainItem.tokens.userAccount)
        } catch {
            XCTFail("Threw error saving to keychain")
        }
        XCTAssertTrue(self.authService.isAuthenticated,
                      "Should be authenticated with valid token")
    }
    
    func testNotAuthenticatedAfterEndingSession() {
        authService.endSession()
        XCTAssertFalse(self.authService.isAuthenticated,
                       "Auth service should not return isAuthenticated true after clearing session")
    }
    
    func testIsAuthenticatedAfterBeginningSession() {
        do {
            try authService.beginSession(authResponse: AuthResponse(access_token: validToken,
                                                                    refresh_token: nil,
                                                                    user: nil))
            XCTAssertTrue(self.authService.isAuthenticated)
        } catch {
            XCTFail("Failed to read saved auth token from keychain")
        }
    }
    
    func testAuthServiceReturnsSavedAuthUser() {
        do {
            try authService.beginSession(authResponse: authResponse)
            XCTAssertEqual(authService.authUser?.id, authResponse.user?.id)
        } catch {
            XCTFail("Failed to read saved auth user from keychain")
        }
    }
}
