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
import Shared

class AccountViewController: FormViewController {
    var appContext: AppContext
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
        
        form +++ Section()
            <<< TextRow {
                $0.tag = "email"
                $0.title = Strings.EmailFieldLabel
                $0.value = appContext.store.user.data?.email
            }
            <<< TextRow {
                $0.tag = "username"
                $0.title = Strings.UsernameFieldLabel
                $0.value = appContext.store.user.data?.username
        }
        
        for row in form.rows {
            row.baseCell.isUserInteractionEnabled = false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
