//
//  CreateArtistViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Eureka
import UrbanApplauseShared

protocol CreateArtistDelegate: class {
    func didCreateArtist(_ artist: Artist)
}

class CreateArtistViewController: FormViewController {
    var networkService: NetworkService
    weak var delegate: CreateArtistDelegate?
    
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
    init(networkService: NetworkService) {
        self.networkService = networkService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveArtist(_:)))
    var loader = ActivityIndicator()
    lazy var loaderButton = UIBarButtonItem(customView: loader)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section("Name")
            <<< TextRow {
                $0.tag = "signing_name"
                $0.add(rule: RuleRequired(msg: "Please provide a name for the artist", id: nil))
                $0.add(rule: RuleMinLength(minLength: 1))
                $0.add(rule: RuleMaxLength(maxLength: 100, msg: "Max length is 100", id: nil))
                $0.onChange { _ in
                    self.onUpdateForm()
                }
                $0.validationOptions = .validatesOnChange
            }
            +++ Section("Bio")
            <<< TextAreaRow {
                $0.tag = "bio"
                $0.placeholder = "Optional"
                $0.title = "Bio"
            }
        
            +++ Section("More")
            <<< TextAreaRow {
                $0.tag = "instagram_username"
                $0.placeholder = "Optional"
                $0.title = "Instagram"
            }
            
        navigationItem.rightBarButtonItem = saveButton
        saveButton.isEnabled = false
    }
    func onUpdateForm() {
        let errors = form.validate()
        navigationItem.rightBarButtonItem?.isEnabled = errors.count == 0
    }
    
    @objc func saveArtist(_: Any) {
        self.isLoading = true
        let endpoint = PrivateRouter.createArtist(values: form.values() as Parameters)
        _ = networkService.request(endpoint) { [weak self] (result: UAResult<ArtistContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.isLoading = false
                    self?.errorMessage = error.userMessage
                case .success(let artistContainer):
                    self?.isLoading = false
                    self?.navigationController?.popViewController(animated: true)
                    self?.delegate?.didCreateArtist(artistContainer.artist)
                }
            }
        }
    }
}
