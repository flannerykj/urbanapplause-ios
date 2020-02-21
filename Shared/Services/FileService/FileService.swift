//
//  ImageCache.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

fileprivate let log = DHLogger.self

public class FileService: NSObject {
    
    public override init() {
        super.init()
        NotificationCenter.default.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main, using: { notification in
            self.clearUnusedImages()
        })
        
    }
    let spacesFileRepository = SpacesFileRepository()
    typealias Handler = (UAResult<FileDownloadJob>) -> Void
    
    private let cache = Cache<String, FileDownloadJob>()

    public func getJobForFile(_ file: File) -> FileDownloadJob {
        log.debug("get job for file: \(file.filename)")
        if let job = self.cache[file.storage_location] {
            // see if job already complete/in progress
            return job
        }
        // create and save reference to a new job
        let job = FileDownloadJob(file: file, spacesFileRepository: spacesFileRepository)
        self.cache[file.storage_location] = job
        return job
    }
    
    public func addLocalData(_ data: Data, for file: File) {
        log.debug("set job for file: \(file.filename)")
        let job = self.getJobForFile(file)
        job.setLocalData(data)
    }
    
    public func clearUnusedImages() {
        cache.clear()
    }
}
