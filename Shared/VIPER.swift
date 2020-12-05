//
//  VIPER.swift
//  Shared
//
//  Created by Flann on 2020-11-22.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import RxSwift


// MARK: - Builder
public protocol Buildable: AnyObject {}

open class Builder<DependencyType> {
    public let dependency: DependencyType
    
    public init(dependency: DependencyType) {
        self.dependency = dependency
    }
}


// MARK: - ViewController

public protocol ViewControllable: AnyObject {
    var uiViewController: UIViewController { get }
}
open class ViewController: UIViewController, ViewControllable {
    public var uiViewController: UIViewController { self }
}

// MARK: - Router
public protocol Routing {
    var interactable: Interactable { get }
    var children: [Routing] { get }
}

open class Router<InteractorType>: Routing {
    public let interactor: InteractorType
    public let interactable: Interactable
    public final var children: [Routing] = []
    
    public init (interactor: InteractorType) {
        self.interactor = interactor
        self.interactable = interactor as! Interactable
    }
    
    public func attachChild(_ child: Routing) {
        children.append(child)
        child.interactable.activate()
    }
}

public protocol ViewableRouting: Routing {
    var viewControllable: ViewControllable { get }
}

open class ViewableRouter<InteractorType, ViewControllerType>: Router<InteractorType>, ViewableRouting {
    public var viewController: ViewControllerType
    public var viewControllable: ViewControllable

    public init(interactor: InteractorType, viewController: ViewControllerType) {
        self.viewController = viewController
        self.viewControllable = viewController as! ViewControllable
        super.init(interactor: interactor)
    }
}


// MARK: - Presenter

public protocol Presentable {}
open class Presenter<ViewControllerType>: Presentable {
    public let viewController: ViewControllerType
    
    public init(viewController: ViewControllerType) {
        self.viewController = viewController
    }
}

// MARK: - Interactor
public protocol Interactable {
    var isActive: Observable<Bool> { get }
    func activate()
    func deactivate()
}
open class Interactor: Interactable {
    private let mutableIsActive: BehaviorSubject<Bool> = .init(value: false)
    
    // MARK: - Interactable
    public var isActive: Observable<Bool> {
        mutableIsActive
    }
    public func activate() {
        mutableIsActive.onNext(true)
    }
    
    public func deactivate() {
        mutableIsActive.onNext(false)
    }
}

open class PresentableInteractor<PresenterType>: Interactor {
    public let presenter: PresenterType
    
    public init(presenter: PresenterType) {
        self.presenter = presenter
    }
}




