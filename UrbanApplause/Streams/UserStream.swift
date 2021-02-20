//
//  UserStream.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-18.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import Shared

protocol UserStream {
    var user: AnyPublisher<User?, Never> { get }
}

protocol MutableUserStream: UserStream {
    func setUser(_ user: User?)
}
class UserStreamImpl: MutableUserStream {
    private let userSubject = CurrentValueSubject<User?, Never>(nil)
    
    
    // MARK: UserStream
    var user: AnyPublisher<User?, Never> { userSubject.eraseToAnyPublisher() }
    
    
    // MARK: MutableUserStream
    
    func setUser(_ user: User?) {
        userSubject.value = user
    }
}
