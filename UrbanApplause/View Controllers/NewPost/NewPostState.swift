//
//  NewPostState.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum NewPostState {
    case initial, gettingLocationData, savingPost, uploadingImages
    
    var title: String {
        switch self {
        case .initial:
            return "New post"
        case .gettingLocationData:
            return "Getting location data..."
        case .savingPost:
            return "Saving post..."
        case .uploadingImages:
            return "Uploading images..."

        }
    }
}
