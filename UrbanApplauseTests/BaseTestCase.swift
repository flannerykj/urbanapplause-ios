//
//  BaseTestCase.swift
//  UrbanApplauseTests
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import XCTest

class BaseTestCase: XCTestCase {
    let timeout: TimeInterval = 5
    
    static var testDirectoryURL: URL {
        return FileManager.temporaryDirectoryURL.appendingPathComponent("com.flannerykj.KijijiTakeHomeTests")
    }
    var testDirectoryURL: URL { return BaseTestCase.testDirectoryURL }
    
    override func setUp() {
        super.setUp()
        
        FileManager.removeAllItemsInsideDirectory(at: testDirectoryURL)
        FileManager.createDirectory(at: testDirectoryURL)
    }
    
    func url(forResource fileName: String, withExtension ext: String) -> URL {
        let bundle = Bundle(for: BaseTestCase.self)
        return bundle.url(forResource: fileName, withExtension: ext)!
    }
    
    /* func assertErrorIsDotError(_ error: Error?,
                              file: StaticString = #file,
                              line: UInt = #line,
                              evaluation: (_ error: DotError) -> Void) {
        guard let error = error?.asDotError else {
            XCTFail("error is not an AFError", file: file, line: line)
            return
        }
        
        evaluation(error)
    }
    
    func assertErrorIsServerTrustEvaluationError(_ error: Error?, file: StaticString = #file, line: UInt = #line, evaluation: (_ reason: AFError.ServerTrustFailureReason) -> Void) {
        assertErrorIsAFError(error, file: file, line: line) { (error) in
            guard case let .serverTrustEvaluationFailed(reason) = error else {
                XCTFail("error is not .serverTrustEvaluationFailed", file: file, line: line)
                return
            }
            
            evaluation(reason)
        }
    } */
    
    func getDateInPast(daysAgo: Int) -> Date? {
        let currentDate = Date()
        var dateComponents = DateComponents()
        dateComponents.setValue(-daysAgo, for: .day)
        return Calendar.current.date(byAdding: dateComponents, to: currentDate)
    }
}
