//
//  ProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-12-28.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Eureka

class AccountViewController: FormViewController {
    var mainCoordinator: MainCoordinator
    
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
        
        form +++ Section()
            <<< TextRow {
                $0.tag = "email"
                $0.title = "Email"
                $0.value = mainCoordinator.store.user.data?.email
            }
            <<< TextRow {
                $0.tag = "username"
                $0.title = "Username"
                $0.value = mainCoordinator.store.user.data?.username
        }
        
        for row in form.rows {
            row.baseCell.isUserInteractionEnabled = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
