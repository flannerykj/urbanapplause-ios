//
//  AuthNetworkServiceTests.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import XCTest

@testable import UrbanApplause

class AuthRequestTests: BaseTestCase {
    let email = "flannj@gmail.ca"
    let password = "cheesecake1234!!"
    let username = "flannj"
    var urlString = ""
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testSuccessfulLogin() {
        
        let endpoint = AuthRouter.authenticate(email: email, password: password, username: username, newUser: false)
        let expectation = self.expectation(description: "Login request should succeed")
       
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "auth_user", withExtension: "json") else {
            XCTFail("Missing file: auth_user.json")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("couldnt get data")
        }
  
        // create the URLSession from mock config
        let session = URLSessionMock(mockResponseData: data, mockResponseError: nil)
        let appContext = AppContext(keychainService: KeychainService(service: "ca.dothealth.test"))
        let networkService = NetworkService(session: session, appContext: appContext)

        _ = networkService.request(endpoint, completion: {(res: UAResult<AuthResponse>) in
            let authResult = try? res.get()
            XCTAssertNotNil(authResult?.access_token)
            XCTAssertNotNil(authResult?.refresh_token)
            expectation.fulfill()
        })
        waitForExpectations(timeout: timeout, handler: nil)
        
    }
    
    func testUnsuccessfulLogin() {
        let endpoint = AuthRouter.authenticate(email: email, password: password, username: username, newUser: false)
        let expectation = self.expectation(description: "Login request should not succeed")
        
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "invalid_auth_user_response", withExtension: "json") else {
            XCTFail("Missing file: invalid_auth_user_response.json")
            return
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("couldnt get data")
        }
        
        // create the URLSession from mock config
        let session = URLSessionMock(mockResponseData: data, mockResponseStatusCode: 400, mockResponseError: nil)
        let appContext = AppContext(keychainService: KeychainService(service: "ca.dothealth.test"))

        let networkService = NetworkService(session: session, appContext: appContext)
        
        _ = networkService.request(endpoint, completion: {(res: UAResult<AuthResponse>) in
            do {
                _ = try res.get()
                XCTFail("Should return an error")
            } catch {
                print("error: \(error)")
                XCTAssertEqual((error as? UAError)?.userMessage, "That email or password is not valid")
                expectation.fulfill()
            }
        })
        waitForExpectations(timeout: timeout, handler: nil)
    }
}
