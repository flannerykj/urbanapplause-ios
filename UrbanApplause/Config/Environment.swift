//
//  Environment.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum Environment: String {
    case developmentDebug = "Debug (Development)"
    case productionDebug = "Debug (Production)"
    case productionRelease = "Release (Production)"

    static var current: Environment {
        guard let configuration = Bundle.main.object(forInfoDictionaryKey: "Configuration")
            as? String else { fatalError("'Configuration not set in Info.Plist") }
        
        guard let env = Environment(rawValue: configuration) else {
            fatalError("Invalid configuration set")
        }
        return env
    }

    var dotEnvFilename: String {
        switch self {
        case .developmentDebug:
            return".env"
        case .productionRelease, .productionDebug:
            return ".env.production"
        }
    }
    
    var keychainServiceID: String {
        switch self {
        case .developmentDebug:
            return"ca.dothealth.dothealthios-dev"
        case .productionRelease, .productionDebug:
            return "ca.dothealth.dothealthios-prod"
        }
    }

    var variables: [String: String] {
        var variables = [String: String]()

        guard let path = Bundle.main.path(forResource: dotEnvFilename, ofType: "") else {
            fatalError("couldn't get .env file")
        }
        let url = URL(fileURLWithPath: path)
        do {
            let contents = try String(contentsOf: url)

            let lines = contents.split(separator: "\n")
            for line in lines {
                let parts = line.split(separator: "=")

                let key = String(parts[0])
                let value = String(parts[1])
                variables[key] = value
            }
        } catch {
            // no env file - build is being run from bitrise. get vars from processInfo
            return ProcessInfo.processInfo.environment
        }
        return variables
    }

}
