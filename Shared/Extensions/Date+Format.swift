//
//  Date.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-17.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public extension Date {
    enum Format: String, CaseIterable {
        // case iso = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        case isoDateOnly = "yyyy-MM-dd" // user DOB format
        case sqlDateFormat = "yyyy-MM-dd'T'HH:mm:ss.'000Z'"
        case adminFormat = "yyyy/MM/dd"
        case filenameStamp = "yyyy-MM-ddTHH:mm:ss" // ISO 8601 - used for creating filenames
        case jsonSchemaDateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'" // resource json schema date format

        case fhirDateTimeFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        case ua = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"  
        
        case fhirTimeFormat = "HH:MM:SS"

        case uiFormat = "MMMM d, yyyy" // Format for displaying dates to user
        case uiFormatShort = "MMM d, yyyy"

        func dateFromString(string: String) -> Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = self.rawValue
            return formatter.date(from: string)
        }

        func stringFromDate(date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = self.rawValue
            return formatter.string(from: date)
        }
    }
    
    var uiFormat: String {
        return self.timeSince()
    }
    
    var justTheDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Date.Format.uiFormat.rawValue
        return dateFormatter.string(from: self)
    }
    
    var filenameDatestamp: String {
        return "\((self.timeIntervalSince1970 * 1000.0).rounded())"
    }
    
    var isInFuture: Bool { return self > Date() }
    var isInPast: Bool { return self < Date() }
    var isToday: Bool { return self == Date() }
}
