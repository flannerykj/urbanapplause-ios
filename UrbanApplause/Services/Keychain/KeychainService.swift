/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A struct for accessing generic password keychain items.
*/

import Foundation
import LocalAuthentication

struct Credentials: Codable {
    var email: String
    var password: String
}

enum KeychainItem {
    case credentials, tokens

    var userAccount: String {
        switch self {
        case .tokens: return "SavedUserCredentials"
        case .credentials: return "SavedUserTokens"
        }
    }
}

enum KeychainError: Error {
    case noData
    case unexpectedItemData
    case unhandledError(status: OSStatus)
}

class KeychainService {
    var service: String
    var accessGroup: String?

    init(service: String = "urbanapplause.com", accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    public func clear(itemAt userAccount: String) {
        let keychainQuery: NSMutableDictionary =
            NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount],
                                forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue])
        
        SecItemDelete(keychainQuery as CFDictionary)
    }
    
    public func load<T: Codable>(itemAt userAccount: String, isSecure: Bool = false) throws -> T {
        var query = keychainQuery(withService: service,
                                  account: userAccount,
                                  accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        if isSecure {
            query[kSecUseOperationPrompt as String] = "Access your password on the keychain" as AnyObject
        }
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noData }
        guard status == noErr else {throw KeychainError.unhandledError(status: status) }
        
        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String: AnyObject],
            let data = existingItem[kSecValueData as String] as? Data
            else {
                print("Unable to parse keychain item")
                throw KeychainError.unexpectedItemData
        }
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            print("Error decoding from keychain: \(error)")
            throw KeychainError.unexpectedItemData
        }
    }

    func save<T: Codable>(item: T, to userAccount: String, isSecure: Bool = false) throws {
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(item)
        do {
            let keychainQuery: NSMutableDictionary =
                NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, encodedData],
                                    forKeys: [kSecClassValue,
                                              kSecAttrServiceValue,
                                              kSecAttrAccountValue,
                                              kSecValueDataValue])

            let access = SecAccessControlCreateWithFlags(nil, // Use the default allocator.
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .userPresence,
            nil)
            
            if isSecure {
                keychainQuery[kSecAttrAccessControl as String] = access as AnyObject?
                keychainQuery[kSecUseAuthenticationContext as String] = LAContext() as AnyObject
            }
            // Delete any existing items
            SecItemDelete(keychainQuery as CFDictionary)

            var queryResult: AnyObject?
            let status = withUnsafeMutablePointer(to: &queryResult) {
                SecItemAdd(keychainQuery as CFDictionary, UnsafeMutablePointer($0))
            }
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        } catch KeychainError.noData {
            /*
             No password was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = keychainQuery(withService: service, account: userAccount, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedData as AnyObject?

            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)

            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    private let kSecClassValue = NSString(format: kSecClass)
    private let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
    private let kSecValueDataValue = NSString(format: kSecValueData)
    private let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
    private let kSecAttrServiceValue = NSString(format: kSecAttrService)
    private let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
    private let kSecReturnDataValue = NSString(format: kSecReturnData)
    private let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)

    private func keychainQuery(withService service: String,
                               account: String? = nil,
                               accessGroup: String? = nil) -> [String: AnyObject] {
        var query = [String: AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?

        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        return query
    }
}
