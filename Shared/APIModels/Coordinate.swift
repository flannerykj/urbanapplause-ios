//
//  Coordinate.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct Coordinate {
    public var latitude: Double
    public var longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
}

extension Coordinate: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let coordsData = try values.decode([Double].self, forKey: .coordinates)
        latitude = coordsData[0]
        longitude = coordsData[1]
    }
}

extension Coordinate: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([latitude, longitude], forKey: .coordinates)
    }
}
public struct CoordinatesContainer: Codable {
    public var coordinates: Coordinate
}
extension Coordinate: Equatable {
    public static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
