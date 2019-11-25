//
//  FileDownloadJob.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

struct FileDownloadSubscriber {
    var subscriberID: String
    var onSuccess: (Data) -> Void
    var onError: (Error) -> Void
    var onUpdateProgress: (Float) -> Void
    var onSubscriptionRemoved: () -> Void
}

class FileDownloadJob: NSObject {
    private var file: File
    private var subscribers: [FileDownloadSubscriber] = []
    private var spacesFileRepository: SpacesFileRepository
    init(file: File, spacesFileRepository: SpacesFileRepository) {
        // setup
        self.file = file
        self.spacesFileRepository = spacesFileRepository
        super.init()
    }
    
    // MARK: Public methods
    public func subscribe(onSuccess: @escaping (Data) -> Void = { _ in },
                          onError: @escaping (Error) -> Void = { _ in },
                          onUpdateProgress: @escaping (Float) -> Void = { _ in },
                          onSubscriptionRemoved: @escaping () -> Void = {}) -> FileDownloadSubscriber {
        
        let subscriber = FileDownloadSubscriber(subscriberID: UUID().uuidString,
                                               onSuccess: onSuccess,
                                               onError: onError,
                                               onUpdateProgress: onUpdateProgress,
                                               onSubscriptionRemoved: onSubscriptionRemoved)
        self.subscribers.append(subscriber)
        
        // send subscriber the most recent data received so far
        if let imageData = imageData {
            subscriber.onSuccess(imageData)
        } else if let error = self.error {
            log.error(error)
            subscriber.onError(error)
        } else if let downloadProgress = self.downloadProgress {
            subscriber.onUpdateProgress(downloadProgress)
        }
        if imageData == nil && !downloading {
            fetchDataFromCDN()
        }
        
        return subscriber
    }
    public func setLocalData(_ data: Data) {
        self.imageData = data
    }
    public func removeSubscriber(_ subscriber: FileDownloadSubscriber) {
        if let index = self.subscribers.firstIndex(where: { $0.subscriberID == subscriber.subscriberID }) {
            let removed = self.subscribers.remove(at: index)
            removed.onSubscriptionRemoved()
        }
        
        if self.subscribers.count == 0 {
            /* self.task?.cancel(byProducingResumeData: { resumeData in
                self.resumeTaskData = resumeData
            }) */
        }
    }
    
    // MARK: Private variables
    private var downloading: Bool = false
    
    private var error: Error? {
        didSet {
            if let error = self.error {
                for subscriber in self.subscribers {
                    subscriber.onError(error)
                }
            }
        }
    }
    private var downloadProgress: Float? {
        didSet {
            if let progress = self.downloadProgress {
                for subscriber in self.subscribers {
                    subscriber.onUpdateProgress(progress)
                }
            }
        }
    }
    private var imageData: Data? { // if set from tmp data
        didSet {
            if let data = self.imageData {
                for subscriber in subscribers {
                    subscriber.onSuccess(data)
                }
            }
        }
    }
    private func fetchDataFromCDN() {
        self.downloading = true
        spacesFileRepository.downloadFile(filename: file.storage_location, completion: { data, error in
            self.downloading = false
            if data != nil {
                 self.imageData = data
            } else {
                log.error(error)
                self.error = S3Error.downloadError(error?.localizedDescription)
            }
        })
    }
}
