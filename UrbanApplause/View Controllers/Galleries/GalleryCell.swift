//
//  GalleryCell.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class GalleryCell: UITableViewCell {
    static let ReuseID = "GalleryCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: GalleryCell.ReuseID)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
