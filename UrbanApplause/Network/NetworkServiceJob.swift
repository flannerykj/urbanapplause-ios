//
//  NetworkServiceJob.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum NetworkServiceJobPriority {
    case primary // requested by user - complete as soon as possible
    case secondary // Used to preload data the user might need later on. Hold until no other primary tasks queued.
}

class NetworkServiceJob {
    var uuid: String
    var task: URLSessionTask
    var completionQueue: DispatchQueue = .main
    weak var sessionDownloadDelegate: URLSessionDownloadDelegate?
    weak var sessionDataDelegate: URLSessionDataDelegate?
    var priority: NetworkServiceJobPriority
    var taskStartedAt: Date?
    
    func startTask() {
        self.taskStartedAt = Date()
        self.task.resume()
    }
    
    func suspendTask() {
        self.taskStartedAt = nil
        self.task.suspend()
    }
    
    init(uuid: String,
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
