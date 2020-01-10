//
//  AuthService.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-03.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

fileprivate let log = DHLogger.self

public class AuthService {
    private var keychainService: KeychainService
    var currentDate: Date { // so that we can set a diff curent date for testing
        return Date()
    }
    
    public init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    public var isAuthenticated: Bool {
        do {
            let tokens: AuthResponse = try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            log.debug("tokens: \(tokens)")
            let decoded = decode(jwtToken: tokens.access_token)
            log.debug("decoded: \(decoded)")
            guard let seconds = decoded["exp"] as? Double else {
                log.debug("expiry \(decoded["exp"] ?? "no expiry value")")
                return false
            }
            let expiryDate = Date(timeIntervalSince1970: seconds)
            log.debug("expiry date: \(expiryDate)")
            return expiryDate > self.currentDate
        } catch {
            return false
        }
    }
    
    public var authUser: User? {
        do {
            let tokens: AuthResponse = try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            return tokens.user
        } catch {
            return nil
        }
    }
    
    public func endSession() {
        keychainService.clear(itemAt: KeychainItem.tokens.userAccount)
    }
    public func beginSession(authResponse: AuthResponse) throws {
        try keychainService.save(item: authResponse, to: KeychainItem.tokens.userAccount)
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
