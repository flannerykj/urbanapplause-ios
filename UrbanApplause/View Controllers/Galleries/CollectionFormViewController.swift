//
//  NewCollectionViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Eureka
import Shared

protocol NewCollectionViewControllerDelegate: class {
    func didCreateCollection(collection: Collection)
    func didUpdateCollection(collection: Collection)
}

class CollectionFormViewController: FormViewController {
    weak var delegate: NewCollectionViewControllerDelegate?
    var appContext: AppContext
    var isLoading: Bool = false
    var errorMessage: String?
    private var hasUnsavedChanges: Bool = false {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled = hasUnsavedChanges
        }
    }
    
    private let existingCollection: Collection?
    
    init(existingCollection: Collection?, appContext: AppContext) {
        self.existingCollection = existingCollection
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var saveButton = UIBarButtonItem(title: "Create",
                                          style: .plain,
                                          target: self,
                                          action: #selector(createCollection(_:)))
    
    lazy var updateButton = UIBarButtonItem(title: "Update",
                                            style: .plain,
                                            target: self,
                                            action: #selector(updateCollection(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        if existingCollection == nil {
            navigationItem.title = Strings.NewGalleryScreenTitle
            navigationItem.rightBarButtonItem = saveButton
        } else {
            navigationItem.title = "Update collection"
            navigationItem.rightBarButtonItem = updateButton
        }
        navigationItem.rightBarButtonItem?.isEnabled = hasUnsavedChanges
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelEditing(_:)))
        form +++ Section()
            <<< TextRow { row in
                row.title = Strings.TitleFieldLabel
                row.tag = "title"
                row.value = existingCollection?.title
                row.onChange { row in
                    self.hasUnsavedChanges = true
                }
            }
            +++ Section(Strings.DescriptionFieldLabel)
            <<< TextAreaRow { row in
                row.title = Strings.DescriptionFieldLabel
                row.tag = "description"
                row.value = existingCollection?.description
                row.onChange { row in
                    self.hasUnsavedChanges = true
                }
            }
            <<< SwitchRow() { row in
                row.tag = "is_public"
                row.title = "Public"
                row.value = existingCollection?.is_public ?? false
                row.onChange { row in
                    self.hasUnsavedChanges = true
                }
            }
        
        if let row = form.rowBy(tag: "title") as? TextRow, existingCollection == nil {
            _ = row.cell.cellBecomeFirstResponder(withDirection: .down)
        }
    }
    
    @objc func cancelEditing(_: UIBarButtonItem) {
        let popOrDismiss = {
            if let nav = self.navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
        if hasUnsavedChanges {
            popOrDismiss()
            // Currently this can be bypassed by swiping down to dismiss.
            
//            let alert = UIAlertController(title: "Abandon unsaved changes?", message: "Your changes will be discarded", preferredStyle: .alert)
//            let discardAction = UIAlertAction(title: "Discard changes", style: .destructive, handler: { _ in
//                alert.dismiss(animated: true, completion: {
//                    popOrDismiss()
//                })
//            })
//            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
//                alert.dismiss(animated: true, completion: nil)
//            })
//            alert.addAction(discardAction)
//            alert.addAction(cancelAction)
//            present(alert, animated: true, completion: nil)
        } else {
            popOrDismiss()
        }
    }
    
    
    @objc func createCollection(_: UIButton) {
        log.debug("pressed create collection")
        guard let userId = appContext.store.user.data?.id else {
            log.error("user data not set")
            return
        }
        var payload = form.values()
        payload["UserId"] = userId
        
        self.isLoading = true
        self.errorMessage = nil
        let endpoint = PrivateRouter.createCollection(values: payload as Parameters)
        _ = appContext.networkService.request(endpoint) {(result: UAResult<CollectionContainer>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let collectionContainer):
                    DispatchQueue.main.async {
                        self.delegate?.didCreateCollection(collection: collectionContainer.collection)
                        self.dismiss(animated: true, completion: nil)
                    }
                case .failure(let error):
                    self.errorMessage = error.userMessage
                    log.error("error creating collection: \(error)")
                }
            }
        }
    }
    
    @objc func updateCollection(_: UIButton) {
        log.debug("pressed update collection")
        guard let userId = appContext.store.user.data?.id else {
            log.error("user data not set")
            return
        }
        guard let collection = existingCollection else {
            log.error("No existing collection")
            return
        }
        var payload = form.values()
        payload["UserId"] = userId
        
        self.isLoading = true
        self.errorMessage = nil
        let endpoint = PrivateRouter.updateCollection(id: collection.id, values: payload as Parameters)
        _ = appContext.networkService.request(endpoint) {(result: UAResult<CollectionContainer>) in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let collectionContainer):
                    DispatchQueue.main.async {
                        self.delegate?.didUpdateCollection(collection: collectionContainer.collection)
                        self.dismiss(animated: true, completion: nil)
                    }
                case .failure(let error):
                    self.errorMessage = error.userMessage
                    log.error("error updating collection: \(error)")
                }
            }
        }
    }
}
