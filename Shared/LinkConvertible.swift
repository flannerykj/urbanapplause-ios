//
//  LinkConvertible.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation


public protocol LinkConvertible {
    var linkText: String { get }
    var internalPath: String { get }
}

extension Artist: LinkConvertible {
    public var linkText: String {
        self.signing_name ?? ""
    }
    
    public var internalPath: String {
        return "artists/\(self.id)"
    }
}

extension User: LinkConvertible {
    public var linkText: String {
        self.username ?? ""
    }
    
    public var internalPath: String {
        return "users/\(self.id)"
    }
}

extension ArtistGroup: LinkConvertible {
    public var linkText: String {
        self.name
    }
    
    public var internalPath: String {
        return "artist_groups/\(self.id)"
    }
}
