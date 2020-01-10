//
//  EditProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import Shared

protocol EditProfileDelegate: class {
    func didUpdateUser(_ user: User)
}

class EditProfileViewController: FormViewController {
    weak var delegate: EditProfileDelegate?
    var appContext: AppContext
    var isLoading = false {
        didSet {
            if isLoading {
                navigationItem.rightBarButtonItem = loaderButton
            } else {
                navigationItem.rightBarButtonItem = saveButton
            }
        }
    }
    var errorMessage: String? = nil {
        didSet {
            
        }
    }
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var loader = ActivityIndicator()
    lazy var loaderButton = UIBarButtonItem(customView: loader)

    lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(pressedSave(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = Strings.EditProfileButtonTitle
        view.backgroundColor = UIColor.backgroundMain
        form +++ Section(Strings.BioFieldLabel)
            <<< TextAreaRow {
                $0.tag = "bio"
                $0.onChange { _ in
                    self.onUpdateForm()
                }
                $0.value = appContext.store.user.data?.bio
        }
        // tableView.separatorColor = UIColor.clear
        
        navigationItem.rightBarButtonItem = saveButton
        saveButton.isEnabled = false
    }
    @objc func pressedSave(_: UIButton) {
        let payload = form.values()
        guard let userId = appContext.store.user.data?.id else {
            log.error("user id not set")
            return
        }
        self.isLoading = true
        let endpoint = PrivateRouter.updateUser(id: userId, values: payload as Parameters)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<UserContainer>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let userContainer):
                    log.debug(userContainer.user)
                    self.appContext.store.user.data = userContainer.user
                    self.delegate?.didUpdateUser(userContainer.user)
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    log.error(error)
                }
            }
        }
    }
    func onUpdateForm() {
        let errors = form.validate()
        navigationItem.rightBarButtonItem?.isEnabled = errors.count == 0
    }
}
