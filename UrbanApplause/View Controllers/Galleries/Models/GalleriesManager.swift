//
//  GalleriesManager.swift
//  UrbanApplause
//
//  Created by Flann on 2020-11-22.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import RxSwift
import Shared

enum GalleryManagerError: Error {
    case errorFetchingGalleries(Error)
    
    var errorMessage: String {
        switch self {
        case .errorFetchingGalleries:
            return "Unable to fetch galleries"
        }
    }
}

protocol GalleriesManaging {
    var errorStream: Observable<String?> { get }
    var galleriesStream: Observable<[Collection]> { get }
    func refresh()
}

class GalleriesManager: NSObject, GalleriesManaging {
    private let disposeBag = DisposeBag()
    
    // MARK: - GalleriesManaging
    var galleriesStream: Observable<[Collection]> { mutableGalleriesStream }
    var errorStream: Observable<String?> { mutableErrorStream }

    func refresh() {
        refreshControl.onNext(())
    }
    
    // MARK: - Private
    let refreshControl: BehaviorSubject<()> = .init(value: ())
    let mutableGalleriesStream: BehaviorSubject<[Collection]> = .init(value: [])
    let mutableErrorStream: BehaviorSubject<String?> = .init(value: nil)

    override init() {
        super.init()
        refreshControl
            .flatMapLatest { _ in
                return self.getGalleries()
                    .materialize()
            }
            .subscribe(onNext: { [weak self] (event: Event<[Collection]>) in
                switch event {
                case .next(let galleries):
                    self?.handleGalleriesResponse(galleries)
                case .error(let error):
                    self?.handleGalleriesError(.errorFetchingGalleries(error))
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func getGalleries() -> Observable<[Collection]> {
        return Observable.just([])
    }
    

    private func handleGalleriesResponse(_ galleries: [Collection]) {
        mutableGalleriesStream.onNext(galleries)
    }
    
    private func handleGalleriesError(_ error: GalleryManagerError) {
        mutableErrorStream.onNext(error.errorMessage)
    }
}

