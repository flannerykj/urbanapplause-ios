//
//  AuthManager.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-17.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine
import Shared

protocol AuthStream: AnyObject {
    var user: AnyPublisher<User?, Never> { get }
    var isAuthenticated: AnyPublisher<Bool, Never> { get }
}

protocol MutableAuthStream: AnyObject {
    func beginSession(email: String, password: String, username: String?, isNewUser: Bool) -> AnyPublisher<(), Error>
    func endSession()
}

class AuthStreamImpl: MutableAuthStream {
    var tokenTimeout: Cancellable?
    private let userSubject = CurrentValueSubject<User?, Never>(nil)
    
    private let authAPIService: AuthAPIService
    private let keychainService: KeychainService
    
    init(authAPIService: AuthAPIService,
         keychainService: KeychainService) {
        self.authAPIService = authAPIService
        self.keychainService = keychainService
    }
    
    var user: AnyPublisher<User?, Never> { userSubject.eraseToAnyPublisher() }

    var isAuthenticated: AnyPublisher<Bool, Never> {
        user
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, username: String) -> AnyPublisher<(), Error> {
        endSession()
        
        return authAPIService.register(email: email, username: username, password: password)
            .tryMap { (authResponse: AuthResponse?) -> () in
                guard let authResponse = authResponse else { throw NSError() }
                try self.keychainService.save(item: authResponse, to: KeychainItem.tokens.userAccount)
                self.userSubject.value = authResponse.user
                self.setTokenExpirationTimeout(authResponse: authResponse)
                return ()
            }
            .eraseToAnyPublisher()
    }
    
    func endSession(didTimeout: Bool = false) {
        tokenTimeout?.cancel()
        keychainService.clear(itemAt: KeychainItem.tokens.userAccount)
        self.userSubject.value = nil
    }
    
    // MARK: AuthManager
    
    private func setTokenExpirationTimeout(authResponse: AuthResponse) {
        let decoded = decode(jwtToken: authResponse.access_token)
        guard let seconds = decoded["exp"] as? Double else {
            self.endSession()
        }
        let expiryDate = Date(timeIntervalSince1970: seconds)
        let remainingTimeInterval: TimeInterval = expiryDate.timeIntervalSinceNow
        tokenTimeout = Timer.publish(every: remainingTimeInterval, on: .main, in: .default)
            .autoconnect()
            .sink { _ in
                self.endSession(didTimeout: true)
            }
    }
    
    private func decode(jwtToken jwt: String) -> [String: Any] {
      let segments = jwt.components(separatedBy: ".")
      return decodeJWTPart(segments[1]) ?? [:]
    }

    private func base64UrlDecode(_ value: String) -> Data? {
      var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

      let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
      let requiredLength = 4 * ceil(length / 4.0)
      let paddingLength = requiredLength - length
      if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
      }
      return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }

    private func decodeJWTPart(_ value: String) -> [String: Any]? {
      guard let bodyData = base64UrlDecode(value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
        let payload = json as? [String: Any] else {
          return nil
      }
      return payload
    }
}
