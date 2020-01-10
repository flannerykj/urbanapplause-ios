//
//  Location.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

import UIKit
import CoreLocation
import MapKit

public struct Location: Codable {
    public var id: Int
    public var apple_place_id: String?
    public var coordinates: Coordinate
    public var street_address: String?
    public var city: String?
    public var country: String?
    public var postal_code: String?
    public var createdAt: Date?
    public var updatedAt: Date?
    
}
public extension Location {
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
    
    var clLocation: CLLocation {
        return CLLocation(latitude: self.coordinates.latitude, longitude: self.coordinates.longitude)
    }
}
