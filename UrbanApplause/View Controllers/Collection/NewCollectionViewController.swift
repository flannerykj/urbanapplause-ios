//
//  NewCollectionViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Eureka

protocol NewCollectionViewControllerDelegate: class {
    func didCreateCollection(collection: Collection)
}

class NewCollectionViewController: FormViewController {
    weak var delegate: NewCollectionViewControllerDelegate?
    var mainCoordinator: MainCoordinator
    var isLoading: Bool = false
    var errorMessage: String?
    
    init(mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    lazy var saveButton = UIBarButtonItem(barButtonSystemItem: .save,
                                          target: self,
                                          action: #selector(createCollection(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "New Gallery"
        navigationItem.rightBarButtonItem = saveButton

        form +++ Section()
            <<< TextRow { row in
                row.title = "Title"
                row.tag = "title"
            }
            +++ Section("Description")
            <<< TextAreaRow { row in
                row.title = "Description"
                row.tag = "description"
            }
            /* <<< SwitchRow() { row in
                row.tag = "public"
                row.title = "Public"
                row.value = true
            } */
        
        if let row = form.rowBy(tag: "title") as? TextRow {
            _ = row.cell.cellBecomeFirstResponder(withDirection: .down)
        }
    }
    
    @objc func createCollection(_: UIButton) {
        log.debug("pressed create collection")
        guard let userId = mainCoordinator.store.user.data?.id else {
            log.error("user data not set")
            return
        }
        var payload = form.values()
        payload["UserId"] = userId
        
        self.isLoading = true
        self.errorMessage = nil
        let endpoint = PrivateRouter.createCollection(values: payload as Parameters)
        _ = mainCoordinator.networkService.request(endpoint) {(result: UAResult<CollectionContainer>) in
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

}
