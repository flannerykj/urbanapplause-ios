//
//  Location.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit

struct Location: Codable {
    var id: Int
    var apple_place_id: String?
    var coordinates: Coordinate
    var street_address: String?
    var city: String?
    var country: String?
    var postal_code: String?
    var createdAt: Date?
    var updatedAt: Date?
    
}
extension Location {
    var description: String {
        var locationStrings = [String]()
       if let city = city, city.count > 0 {
           locationStrings.append(city)
       }
        if let address = street_address, address.count > 0 {
            locationStrings.append(address)
        }
       if let country = country, country.count > 0 {
           locationStrings.append(country)
       }
        return locationStrings.joined(separator: ", ")
    }
}
