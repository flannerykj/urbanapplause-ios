//
//  ImageCache.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-13.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

class FileService: NSObject {
    let spacesFileRepository = SpacesFileRepository()
    typealias Handler = (UAResult<FileDownloadJob>) -> Void
    
    private let cache = Cache<String, FileDownloadJob>()

    public func getJobForFile(_ file: File) -> FileDownloadJob? {
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
        let job = self.getJobForFile(file)
        job?.setLocalData(data)
    }
    
    public func clearUnusedImages() {
        cache.clear()
    }
}
