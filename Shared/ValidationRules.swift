//
//  ValidationRules.swift
//  Shared
//
//  Created by Flann on 2021-02-11.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Eureka

public struct RuleRegexMatch: RuleType {
    let regexString: String
    
    public var id: String?
    public var validationError: ValidationError
    
    public init(regexString: String, errorMessage: String, id: String? = nil) {
        self.regexString = regexString
        validationError = ValidationError(msg: errorMessage)
        self.id = id
    }
    
    public func isValid(value: String?) -> ValidationError? {
        guard let value = value, !value.isEmpty else { return nil }
        let predicate = NSPredicate(format:"SELF MATCHES %@", regexString)
        if predicate.evaluate(with: value) { return nil }
        return validationError
    }
}
