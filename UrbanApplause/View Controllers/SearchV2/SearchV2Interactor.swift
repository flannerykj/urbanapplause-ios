//
//  SearchV2Interactor.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-15.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation

import Foundation
import Combine
import Shared

protocol SearchV2ViewControllable: AnyObject {
    var listener: SearchV2ViewControllerListener? { get set }
    func updateSavedSearches(_ searches: [SavedSearch])
}
protocol SearchV2Listener: AnyObject {
    func searchV2Controller(_ controller: SearchV2ViewController, didSelectLocation location: Location)
}

class SearchV2Interactor: NSObject, SearchV2ViewControllerListener {

    weak var listener: SearchV2Listener?
    private let appContext: AppContext
    private var cancellables = Set<AnyCancellable>()
    private weak var viewControllable: SearchV2ViewControllable?
    private var savedSearches: [SavedSearch] = []
    
    init(appContext: AppContext, viewControllable: SearchV2ViewControllable) {
        self.appContext = appContext
        self.viewControllable = viewControllable
        super.init()
        viewControllable.listener = self
    }

    // MARK: SearchV2ViewControllerListener
    
    func searchV2GetSavedSearches() {
        guard appContext.authService.isAuthenticated else { return }
        _ = self.appContext.networkService.request(PrivateRouter.getSavedSearches, completion: { (result: UAResult<SavedSearchesResponse>) in
            switch result {
            case .success(let response):
                self.savedSearches = response.saved_searches
                self.viewControllable?.updateSavedSearches(response.saved_searches)
            case .failure(let error):
                log.error(error)
            }
        })
    }
    
    func searchV2Controller(_ controller: SearchV2ViewController, didSelectLocation location: Location) {
        listener?.searchV2Controller(controller, didSelectLocation: location)
    }
}
