//
//  CreateArtistViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-23.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Eureka
import Shared

protocol CreateArtistDelegate: class {
    func createArtistController(_ controller: CreateArtistViewController,
                                didCreateArtist artist: Artist)
}

class CreateArtistViewController: FormViewController {
    var appContext: AppContext
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
    
    var showMoreOptions: Bool = false {
        didSet {
            if let toggleableSection = form.sectionBy(tag: "toggleable_fields") {
                if let buttonRow = form.rowBy(tag: "toggle_fields_button") as? ButtonRow {
                    buttonRow.title = showMoreOptions ? Strings.ShowFewerFieldsButtonTitle : Strings.ShowMoreFieldsButtonTitle
                    buttonRow.updateCell()
                }
                toggleableSection.hidden = Condition(booleanLiteral: !showMoreOptions)
                toggleableSection.evaluateHidden()
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
    
    lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveArtist(_:)))
    var loader = ActivityIndicator()
    lazy var loaderButton = UIBarButtonItem(customView: loader)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.startAnimating()
        form +++ Section("Signing name")
            <<< TextRow {
                $0.tag = "signing_name"
                $0.placeholder = "i.e. the name used to sign work"
                $0.add(rule: RuleRequired(msg: Strings.MissingArtistNameError, id: nil))
                $0.add(rule: RuleMinLength(minLength: 1, msg: Strings.MinCharacterCountError(1)))
                $0.add(rule: RuleMaxLength(maxLength: 100, msg: Strings.MaxCharacterCountError(100), id: nil))
                $0.onChange { _ in
                    self.onUpdateForm()
                }
                $0.validationOptions = .validatesOnChange
            }
            +++ Section(Strings.BioFieldLabel)
            <<< TextAreaRow {
                $0.tag = "bio"
                $0.placeholder = Strings.OptionalFieldLabel
                $0.title = Strings.BioFieldLabel
            }
            +++ Section(Strings.SocialFormSectionTitle)
            <<< TwitterRow {
                $0.tag = "instagram_handle"
                $0.title = Strings.InstagramHandleFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
            }
            <<< TwitterRow {
                $0.tag = "twitter_handle"
                $0.title = Strings.TwitterHandleFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
            }

            <<< URLRow {
                $0.title = Strings.FacebookURLFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
            }
            <<< URLRow {
                $0.title = Strings.WebsiteURLFieldLabel
                $0.placeholder = Strings.OptionalFieldLabel
            }
        
            +++ Section()
            <<< ButtonRow {
                $0.tag = "toggle_fields_button"
                $0.title = Strings.ShowMoreFieldsButtonTitle
                $0.onCellSelection { _, _ in
                    self.showMoreOptions = !self.showMoreOptions
                }
            }
        
            // Toggleable section
            +++ Section {
                $0.tag = "toggleable_fields"
                $0.hidden = Condition(booleanLiteral: !self.showMoreOptions)
            }
        
            <<< TextRow {
                $0.tag = "first_name"
                $0.placeholder = "First Name"
                $0.add(rule: RuleRequired(msg: Strings.MissingArtistNameError, id: nil))
                $0.add(rule: RuleMaxLength(maxLength: 100, msg: Strings.MaxCharacterCountError(100), id: nil))
                $0.onChange { _ in
                    self.onUpdateForm()
                }
                $0.validationOptions = .validatesOnChange
            }
        
            <<< TextRow {
                $0.tag = "last_name"
                $0.placeholder = "Last Name"
                $0.add(rule: RuleRequired(msg: Strings.MissingArtistNameError, id: nil))
                $0.add(rule: RuleMaxLength(maxLength: 100, msg: Strings.MaxCharacterCountError(100), id: nil))
                $0.onChange { _ in
                    self.onUpdateForm()
                }
                $0.validationOptions = .validatesOnChange
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
        _ = appContext.networkService.request(endpoint) { [weak self] (result: UAResult<ArtistContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.isLoading = false
                    self?.showAlert(title: Strings.ErrorAlertTitle, message: error.userMessage)
                case .success(let artistContainer):
                    guard let s = self else { return }
                    s.isLoading = false
                    s.delegate?.createArtistController(s, didCreateArtist: artistContainer.artist)
                }
            }
        }
    }
}
