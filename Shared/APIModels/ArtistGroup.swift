//
//  ArtistGroup.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation


public struct ArtistGroup: Codable {
    public var id: Int
    public var name: String
    public var group_type: ArtistGroupType
    public var Posts: [Post]?
    public var Artists: [Artist]?
}
extension ArtistGroup: Equatable {
    
}
public enum ArtistGroupType: String, CaseIterable, Codable {
    case crew, gallery
}

public struct ArtistGroupContainer: Codable {
    public var artist_group: ArtistGroup
}
public struct ArtistGroupsContainer: Codable {
    public var artist_groups: [ArtistGroup]
}
