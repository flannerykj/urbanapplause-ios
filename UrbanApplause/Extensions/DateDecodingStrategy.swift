//
//  DateDecodingStrategy.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-10.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation   
import UrbanApplauseShared

extension JSONDecoder.DateDecodingStrategy {

    static func createStrategy(acceptedDateFormats: [Date.Format]) -> JSONDecoder.DateDecodingStrategy {
        return JSONDecoder.DateDecodingStrategy.custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            for dateFormat in acceptedDateFormats {
                dateFormatter.dateFormat = dateFormat.rawValue
                if let decodedDate = dateFormatter.date(from: dateString) {
                    return decodedDate
                }
            }
            log.error("No matching date format found for date string: \(dateString). date not decoded")
            throw NetworkError.decodingError(error: NSError())
        })
    }
}
