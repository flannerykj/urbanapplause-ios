//
//  CloudinaryService.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-10-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Cloudinary

fileprivate let log = DHLogger.self

public class CloudinaryService {
    private let config = CLDConfiguration(cloudName: Config.cloudinaryCloudName, apiKey: Config.cloudinaryApiKey, apiSecret: Config.cloudinaryApiSecret, secure: true)
    private let cloudinary: CLDCloudinary
    
    public init() {
        cloudinary = CLDCloudinary(configuration: config)
        
    }
    
    public func downloadFile(filename: String,
                             transformation: CLDTransformation?,
                             updateProgress: @escaping (Double) -> Void,
                             completion: @escaping (Data?, RemoteImageError?) -> Void) {
        let publicId = filename
        let urlGen = cloudinary.createUrl()
        
        if let transformation = transformation {
            urlGen.setTransformation(transformation)
        }
        
        guard let url = urlGen.setResourceType(CLDUrlResourceType.image).generate(publicId, signUrl: true) else {
            log.error("Invalid filename")
            completion(nil, .invalidFilename)
            return
        }

        let downloader = cloudinary.createDownloader()
        
        downloader.fetchImage(url, completionHandler:  { (responseImage, error) in
            if let error = error {
                log.error(error)
                return
            }
            if let img = responseImage {
                DispatchQueue.main.async {
                    completion(img.jpegData(compressionQuality: 1), nil)
                }
            } else {
                log.error("No data returned")
                completion(nil, .noData)
            }
        })
    }
    
    public func uploadFile(data: Data, publicId: String, onCompletion: @escaping (Bool, Error?) -> ()) {
        let params: CLDUploadRequestParams = CLDUploadRequestParams()
            .setPublicId(publicId)
            .setTransformation(CLDTransformation().setQuality(.auto(.good)))
        
        let uploader = cloudinary.createUploader()
        uploader.signedUpload(data: data, params: params, progress: { progress in
            
        }, completionHandler: { result, error in
            if let err = error {
                print(err)
                onCompletion(false, err)
            } else {
                print("No error")
                if let res = result {
                    print(res)
                    onCompletion(true, nil)
                } else {
                    onCompletion(false, nil)
                }
            }
        })
    }
}

