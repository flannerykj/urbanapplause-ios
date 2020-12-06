//
//  GalleriesTableDataSource.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

class GalleriesTableSource: UITableViewDiffableDataSource<GalleriesSection, GalleryCellViewModel> {
    private let isEditable: Bool
    
    init(tableView: UITableView, cellProvider: @escaping UITableViewDiffableDataSource<GalleriesSection, GalleryCellViewModel>.CellProvider, isEditable: Bool) {
        self.isEditable = isEditable
        super.init(tableView: tableView, cellProvider: cellProvider)
        
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.snapshot().sectionIdentifiers[section].title
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        isEditable
    }
}
