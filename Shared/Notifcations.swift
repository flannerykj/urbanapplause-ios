//
//  Notifcations.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-11.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
extension Notification.Name {
    public static let UploadDidComplete = Notification.Name("UploadDidComplete")
    public static let DisplayThemeChanged = Notification.Name("DisplayThemeChanged")
    public static let ReachabilityStatusChanged = Notification.Name("ReachabilityStatusChanged")
    public static let LocalPreferencesChanged = Notification.Name("LocalPreferencesChanged")
    public static let AuthStatusChanged = Notification.Name("AuthStatusChanged")

    public static let UserDidDeletePost = Notification.Name("UserAuthoredPostsUpdated")
    public static let UserDidAddPost = Notification.Name("UserAuthoredPostsUpdated")
    public static let UserApplauseUpdated = Notification.Name("UserApplauseUpdated")
    public static let UserVisitsUpdated = Notification.Name("UserVisitsUpdated")
    public static let UserCollectionsUpdated = Notification.Name("UserVisitsUpdated")
}
