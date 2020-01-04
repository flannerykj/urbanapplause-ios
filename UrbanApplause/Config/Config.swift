//
//  Config.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct Config {
    static let apiEndpoint = Environment.current.variables["API_ENDPOINT"]! as String
    static let webEndpoint = Environment.current.variables["WEB_HOST"]! as String
    static let awsAccessKeyId = Environment.current.variables["AWS_ACCESS_KEY_ID"]! as String
    static let awsSecretAccessKey = Environment.current.variables["AWS_SECRET_ACCESS_KEY"]! as String
    static let awsBucketName = Environment.current.variables["AWS_BUCKET_NAME"]! as String
    
    static let appGroupIdentifier = "group.com.urbanapplause.ios"
    static let iso = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    static let tosURL = URL(string: "\(Config.webEndpoint)/terms-of-service")!
    static let privacyURL = URL(string: "\(Config.webEndpoint)/privacy-policy")!
    static let cookieUseURL = URL(string: "\(Config.webEndpoint)/cookie-usage")!
}
