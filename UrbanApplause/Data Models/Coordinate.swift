//
//  Coordinate.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-22.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct Coordinate {
    var latitude: Double
    var longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
}

extension Coordinate: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let coordsData = try values.decode([Double].self, forKey: .coordinates)
        latitude = coordsData[0]
        longitude = coordsData[1]
    }
}

extension Coordinate: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([latitude, longitude], forKey: .coordinates)
    }
}
struct CoordinatesContainer: Codable {
    var coordinates: Coordinate
}
extension Coordinate: Equatable {
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
