//
//  DateExtensions.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public extension Date {
    /*
     Formats a date as the time since that date (e.g., “Last week, yesterday, etc.”).
     
     - Parameter from: The date to process.
     - Parameter numericDates: Determines if we should return a numeric variant, e.g. "1 month ago" vs. "Last month".
     
     - Returns: A string with formatted `date`.
     */
    
    // swiftlint:disable cyclomatic_complexity
    func timeSince() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([
            .year,
            .weekOfYear,
            .month,
            .day,
            .hour,
            .minute,
            .second], from: self, to: Date())
        
        if components.year! >= 2 {
            let format = NSLocalizedString("%d years ago", comment: "")
            return String(format: format, components.year!)
        } else if components.year! >= 1 {
            return NSLocalizedString("Last year", comment: "")
        } else if components.month! >= 2 {
            let format = NSLocalizedString("%d months ago", comment: "")
            return String(format: format, components.month!)
        } else if components.month! >= 1 {
            return NSLocalizedString("Last month", comment: "")
        } else if components.weekOfYear! >= 2 {
            let format = NSLocalizedString("%d weeks ago", comment: "")
            return String(format: format, components.weekOfYear!)
        } else if components.weekOfYear! >= 1 {
            return NSLocalizedString("Last week", comment: "")
        } else if components.day! >= 2 {
            let format = NSLocalizedString("%d days ago", comment: "")
            return String(format: format, components.day!)
        } else if components.day! >= 1 {
            return NSLocalizedString("Yesterday", comment: "")
        } else if components.hour! >= 2 {
            let format = NSLocalizedString("%d hours ago", comment: "")
            return String(format: format, components.hour!)
        } else if components.hour! >= 1 {
            return NSLocalizedString("An hour ago", comment: "")
        } else if components.minute! >= 2 {
            let format = NSLocalizedString("%d minutes ago", comment: "")
            return String(format: format, components.minute!)
        } else if components.minute! >= 1 {
            return NSLocalizedString("A minute ago", comment: "")
        } else if components.second! >= 3 {
            let format = NSLocalizedString("%d seconds ago", comment: "")
            return String(format: format, components.second!)
        } else {
            return NSLocalizedString("Just now", comment: "")
        }
    }
}
