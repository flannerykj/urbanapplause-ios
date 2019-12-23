//
//  GalleryCellViewModel.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-20.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine


class GalleryCellViewModel {
    var gallery: Gallery
    var isSelected: Bool = false
    
    init(gallery: Gallery) {
        self.gallery = gallery
    }
}
