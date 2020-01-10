//
//  NewPostState.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared

enum NewPostState {
    case initial, gettingLocationData, savingPost, uploadingImages
    
    var title: String {
        switch self {
        case .initial:
            return Strings.NewPostScreenTitle
        case .gettingLocationData:
            return Strings.GettingLocationStatus
        case .savingPost:
            return Strings.SavingPostStatus
        case .uploadingImages:
            return Strings.UploadingImagesStatus

        }
    }
}
