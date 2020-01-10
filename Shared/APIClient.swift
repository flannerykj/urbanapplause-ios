//
//  NetworkService.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

fileprivate let log = DHLogger.self

public protocol DownloadService: NSObject {
    func download(_ route: EndpointConfiguration,
                  sessionDelegate: URLSessionDownloadDelegate?,
                  priority: NetworkServiceJobPriority) throws -> NetworkServiceJob?
}

public class APIClient: NSObject, NetworkServiceProtocol {
    private let maxActiveJobs = 5
    private let requestTimeoutInterval: Double = 180
    public var session: URLSession = URLSession(configuration: .default)
    
    private var activeJobs: [NetworkServiceJob] = []
    private var pendingPrimaryJobs: [NetworkServiceJob] = []
    private var pendingSecondaryJobs: [NetworkServiceJob] = []
    private var customHeaders: [String: String]
    private var handleAuthError: (UAServerError) -> Void
    
    public init(session: URLSession? = nil,
         customHeaders: [String: String],
         handleAuthError: @escaping (UAServerError) -> Void) {
        self.handleAuthError = handleAuthError
        self.customHeaders = customHeaders
        super.init()
        if let customSesssion = session {
            log.warning("using injected session")
            self.session = customSesssion
        } else {
            self.session = URLSession(configuration: sessionConfig,
                                      delegate: self,
                                      delegateQueue: OperationQueue.main) // Allow for custom session to be injected for testing purposes.
        }
        
    }
    public func setCustomHeaders(_ headers: [String : String]) {
        self.customHeaders = headers
    }
    public func getCustomHeaders() -> [String : String] {
        return self.customHeaders
    }
    public func onReceiveAccessDeniedError(error serverError: UAServerError) {
        // self.appContext.endSession()
    }
    
    // Data task (use for uploads as well as get, post etc.)
    public func request<T>(_ route: EndpointConfiguration,
                           sessionDataDelegate: URLSessionDataDelegate? = nil,
                           priority: NetworkServiceJobPriority = .primary,
                           completion: @escaping (UAResult<T>) -> Void) -> NetworkServiceJob? where T: Decodable {
        do {
            let request = try self.buildRequest(from: route)
            let jobID = UUID().uuidString
            
            let task = self.session.dataTask(with: request) { data, response, error in
                
                let result: UAResult<T> = self.handleResponse(data: data, response: response, error: error)
                completion(result)
                self.onJobCompletion(jobID: jobID)
            }
            
            let job = NetworkServiceJob(uuid: jobID,
                                        task: task,
                                        sessionDataDelegate: sessionDataDelegate,
                                        priority: priority)
            addJob(job: job)
            return job
        } catch let error as UAError {
            log.error("error while buildding URL request: \(error)")
            DispatchQueue.main.async {
                completion(UAResult.failure(error))
            }
        } catch {
            log.warning("Caught non-UA error")
        }
        return nil
    }
    
    public func requestOnBackgroundTask(_ route: EndpointConfiguration,
                                           session: URLSession) {
        do {
            let request = try self.buildRequest(from: route)
            let task = session.dataTask(with: request)
            task.resume()
        } catch {
            log.error(error)
        }
    }
    
    private func addJob(job: NetworkServiceJob) {
        switch job.priority {
        case .primary:
            // Immediately suspend any secondary-priority jobs currently active.
            if let activeSecondaryJobIndex = activeJobs.firstIndex(where: { $0.priority == .secondary }) {
                let secondaryJob = activeJobs.remove(at: activeSecondaryJobIndex)
                secondaryJob.suspendTask()
                pendingSecondaryJobs.append(secondaryJob)
            }
            // Begin task if room on activeJobs queue
            if activeJobs.count < maxActiveJobs {
                activeJobs.append(job)
                job.startTask()
            } else {
                pendingPrimaryJobs.append(job)
            }
        case .secondary:
            // Start job only if no primary-priority jobs are currently in progress
            if activeJobs.count == 0 {
                activeJobs.append(job)
                job.startTask()
            } else {
                pendingSecondaryJobs.append(job)
            }
        }
    }
    
    private func onJobCompletion(jobID: String) {
        guard let completedJobIndex = self.activeJobs.firstIndex(where: { $0.uuid == jobID }) else { return }
        let completedJob = self.activeJobs.remove(at: completedJobIndex)
        if let date = completedJob.taskStartedAt {
            let request = completedJob.task.currentRequest
            if let httpMethod = request?.httpMethod, let url = request?.url?.absoluteString {
                log.debug("\(httpMethod) request to \(url) completed in \(Date().timeIntervalSince(date)) seconds")
            }
        }
        var nextJob: NetworkServiceJob?
        if pendingPrimaryJobs.count > 0 {
            nextJob = pendingPrimaryJobs.removeFirst()
            
        } else if pendingSecondaryJobs.count > 0 && activeJobs.count == 0 {
            // Start secondary job only if no primary-priority jobs are currently in progress
            log.debug("Dequeued secondary job")
            nextJob = pendingSecondaryJobs.removeFirst()
        }
        
        guard let job = nextJob else { return }
        job.startTask()
        activeJobs.append(job)
    }
}

extension APIClient: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        let job = self.activeJobs.first(where: { $0.task == downloadTask })
        job?.sessionDownloadDelegate?.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
    
    public func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didResumeAtOffset fileOffset: Int64,
                    expectedTotalBytes: Int64) {
        
        let job = self.activeJobs.first(where: { $0.task == downloadTask })
        job?.sessionDownloadDelegate?.urlSession?(session, downloadTask: downloadTask,
                                                  didResumeAtOffset: fileOffset,
                                                  expectedTotalBytes: expectedTotalBytes)
    }
    
    public func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        let job = self.activeJobs.first(where: { $0.task == downloadTask })
        job?.sessionDownloadDelegate?.urlSession?(session,
                                                  downloadTask: downloadTask,
                                                  didWriteData: bytesWritten,
                                                  totalBytesWritten: totalBytesWritten,
                                                  totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }
}
extension APIClient: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        
        let job = self.activeJobs.first(where: { $0.task == task })
        job?.sessionDataDelegate?.urlSession?(session,
                                              task: task,
                                              didSendBodyData: bytesSent,
                                              totalBytesSent: totalBytesSent,
                                              totalBytesExpectedToSend: totalBytesExpectedToSend)
    }
    open func urlSession(_ session: URLSession,
                         task: URLSessionTask,
                         didCompleteWithError error: Error?) {
        
        let job = self.activeJobs.first(where: { $0.task == task })
        job?.sessionDataDelegate?.urlSession?(session, task: task, didCompleteWithError: error)
    }
}

