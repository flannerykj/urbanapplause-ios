//
//  Config.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-01.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public struct Config {
    public static let apiEndpoint = Environment.current.variables["API_ENDPOINT"]! as String
    public static let webEndpoint = Environment.current.variables["WEB_HOST"]! as String
    public static let cloudinaryCloudName = Environment.current.variables["CLOUDINARY_CLOUD_NAME"]! as String
    public static let cloudinaryApiKey = Environment.current.variables["CLOUDINARY_API_KEY"]! as String
    public static let cloudinaryApiSecret = Environment.current.variables["CLOUDINARY_API_SECRET"]! as String

    public static let appGroupIdentifier = "group.com.urbanapplause.ios"
    public static let iso = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    public static let tosURL = URL(string: "\(Config.webEndpoint)/terms-of-service")!
    public static let privacyURL = URL(string: "\(Config.webEndpoint)/privacy-policy")!
    public static let cookieUseURL = URL(string: "\(Config.webEndpoint)/cookie-usage")!
}
