//
//  CreateArtistGroupViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Eureka
import Shared

protocol CreateArtistGroupDelegate: class {
    func createArtistGroupController(_ controller: CreateArtistGroupViewController,
                                didCreateArtistGroup artistGroup: ArtistGroup)
}

class CreateArtistGroupViewController: FormViewController {
    var appContext: AppContext
    weak var delegate: CreateArtistGroupDelegate?
    
    var isLoading = false {
        didSet {
            if isLoading {
                navigationItem.rightBarButtonItem = loaderButton
            } else {
                navigationItem.rightBarButtonItem = saveButton
            }
        }
    }
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveArtistGroup(_:)))
    var loader = ActivityIndicator()
    lazy var loaderButton = UIBarButtonItem(customView: loader)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.startAnimating()
        form +++ Section(Strings.NameFieldLabel)
            <<< TextRow {
                $0.tag = "name"
                $0.add(rule: RuleRequired(msg: Strings.MissingArtistGroupNameError, id: nil))
                $0.add(rule: RuleMinLength(minLength: 1, msg: Strings.MinCharacterCountError(1)))
                $0.add(rule: RuleMaxLength(maxLength: 100, msg: Strings.MaxCharacterCountError(100), id: nil))
                $0.onChange { _ in
                    self.onUpdateForm()
                }
                $0.validationOptions = .validatesOnChange
            }
            +++ Section()
            <<< PushRow<ArtistGroupType> { row in
                row.tag = "group_type"
                row.title = Strings.ArtistGroupTypeFieldLabel
                row.options = ArtistGroupType.allCases
                row.value = .crew
            }
//            +++ Section(Strings.BioFieldLabel)
//            <<< TextAreaRow {
//                $0.tag = "bio"
//                $0.placeholder = Strings.OptionalFieldLabel
//                $0.title = Strings.BioFieldLabel
//            }
            +++ Section(Strings.SocialFormSectionTitle)
            <<< TwitterRow {
                $0.tag = "instagram_handle"
                $0.title = Strings.InstagramHandleFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
                $0.onChange { row in
                    
                }
            }
            <<< TwitterRow {
                $0.tag = "twitter_handle"
                $0.title = Strings.TwitterHandleFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
                $0.onChange { row in
                    
                }
            }

            <<< URLRow {
                $0.title = Strings.FacebookURLFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
            }
            <<< URLRow {
                $0.title = Strings.WebsiteURLFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel

            }
        navigationItem.rightBarButtonItem = saveButton
        saveButton.isEnabled = false
    }
    func onUpdateForm() {
        let errors = form.validate()
        navigationItem.rightBarButtonItem?.isEnabled = errors.count == 0
    }
    
    @objc func saveArtistGroup(_: Any) {
        self.isLoading = true
        var payload = form.values()
        if let groupType = form.values()["group_type"] as? ArtistGroupType {
            payload["group_type"] = groupType.rawValue
        }
        log.debug("payload: \(payload)")
        let endpoint = PrivateRouter.createArtistGroup(values: payload as Parameters)
        _ = appContext.networkService.request(endpoint) { [weak self] (result: UAResult<ArtistGroupContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.isLoading = false
                    self?.showAlert(title: Strings.ErrorAlertTitle, message: error.userMessage)
                case .success(let artistGroupContainer):
                    guard let s = self else { return }
                    s.isLoading = false
                    s.delegate?.createArtistGroupController(s, didCreateArtistGroup: artistGroupContainer.artist_group)
                }
            }
        }
    }
}
