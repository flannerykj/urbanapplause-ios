//
//  NetworkServiceJob.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine

public enum NetworkServiceJobPriority {
    case primary // requested by user - complete as soon as possible
    case secondary // Used to preload data the user might need later on. Hold until no other primary tasks queued.
}

public class NetworkServiceJob {
    var uuid: String
    var task: URLSessionTask
    var completionQueue: DispatchQueue = .main
    weak var sessionDownloadDelegate: URLSessionDownloadDelegate?
    weak var sessionDataDelegate: URLSessionDataDelegate?
    var priority: NetworkServiceJobPriority
    var taskStartedAt: Date?

    public func startTask() {
        self.taskStartedAt = Date()
        self.task.resume()
    }
    
    public func suspendTask() {
        self.taskStartedAt = nil
        self.task.suspend()
    }
    
    public init(uuid: String,
         task: URLSessionTask,
         sessionDownloadDelegate: URLSessionDownloadDelegate? = nil,
         sessionDataDelegate: URLSessionDataDelegate? = nil,
         priority: NetworkServiceJobPriority = .primary) {
        
        self.uuid = uuid
        self.task = task
        self.sessionDownloadDelegate = sessionDownloadDelegate
        self.sessionDataDelegate = sessionDataDelegate
        self.priority = priority
    }
}
