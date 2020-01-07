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

        if let name = self.name, name.count > 0 {
            locationInfo.append(name)
        }
        // Street address
        if let street = self.thoroughfare {
            locationInfo.append(street)
        }
        
        // City
        if let city = self.subAdministrativeArea, city.count > 0 {
            locationInfo.append(city)
        } else if let locality = self.locality, locality.count > 0 {
            locationInfo.append(locality)
        } else if let subLocality = self.subLocality, subLocality.count > 0 {
            locationInfo.append(subLocality)
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
