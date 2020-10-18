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
            self.clearFullResImageData()
        })
        
    }
    let spacesFileRepository = CloudinaryService()
    typealias Handler = (UAResult<FileDownloadJob>) -> Void
    
    private let fullResImageCache = Cache<String, FileDownloadJob>()
    private let thumbImageCache = Cache<String, FileDownloadJob>()

    public func getJobForFile(_ file: File, isThumb: Bool) -> FileDownloadJob {
        let cache: Cache = isThumb ? thumbImageCache : fullResImageCache
        if let job = cache[file.storage_location] {
            // see if job already complete/in progress
            return job
        }
        // create and save reference to a new job
        let job = FileDownloadJob(file: file, spacesFileRepository: spacesFileRepository, isThumb: isThumb)
        cache[file.storage_location] = job
        return job
    }
    
    public func addLocalData(_ data: Data, for file: File, isThumb: Bool) {
        log.debug("set job for file: \(file.filename)")
        let job = self.getJobForFile(file, isThumb: isThumb)
        job.setLocalData(data)
    }
    
    public func clearFullResImageData() {
        fullResImageCache.clear()
    }
}
