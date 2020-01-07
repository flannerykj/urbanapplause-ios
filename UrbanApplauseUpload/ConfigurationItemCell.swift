//
//  ConfigurationItemCell.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Social
import MobileCoreServices


class ConfigurationItemCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: nil)
        self.accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var configurationItem: SLComposeSheetConfigurationItem? {
        didSet {
            self.textLabel?.text = configurationItem?.title
            self.detailTextLabel?.text = configurationItem?.value
        }
    }
}
