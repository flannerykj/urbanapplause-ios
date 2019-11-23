//
//  CLLocation.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import MapKit

extension CLPlacemark {
    var title: String {
        var locationInfo = [String]()
        log.debug("location info: \(locationInfo)")
        // Street address
        if let street = self.thoroughfare {
            locationInfo.append(street)
        }
        // City
        if let city = self.subAdministrativeArea {
            locationInfo.append(city)
        }
        // Zip code
        if let zip = self.isoCountryCode {
            locationInfo.append(zip)
        }
        // Country
        if let country = self.country {
            locationInfo.append(country)
        }
        return locationInfo.joined(separator: ", ")
    }
}
