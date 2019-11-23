//
//  URLSessionMock.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
@testable import UrbanApplause

class URLSessionMock: URLSession {
    var mockResponseData: Data?
    var mockResponseError: Error?
    var mockResponseStatusCode: Int
    
    init(mockResponseData: Data?, mockResponseStatusCode: Int = 200, mockResponseError: Error?) {
        self.mockResponseStatusCode = mockResponseStatusCode
        self.mockResponseData = mockResponseData
        self.mockResponseError = mockResponseError
    }
    
    override func dataTask(with request: URLRequest,
                           completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let data = self.mockResponseData
        let error = self.mockResponseError
        let response = HTTPURLResponse(url: request.url!,
                                       statusCode: self.mockResponseStatusCode,
                                       httpVersion: nil,
                                       headerFields: nil)
        
        let task = URLSessionDataTaskMock {
            completionHandler(data, response, error)
        }
        task._currentRequest = request
        return task
    }
    
}
