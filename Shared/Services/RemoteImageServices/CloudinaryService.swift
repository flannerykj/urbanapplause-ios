//
//  CloudinaryService.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-10-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Cloudinary

public class CloudinaryService {
    private let config = CLDConfiguration(cloudName: Config.cloudinaryCloudName, apiKey: Config.cloudinaryApiKey)
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
        
        guard let url = urlGen.setResourceType(CLDUrlResourceType.image).generate(publicId, signUrl: false) else {
            completion(nil, .invalidFilename)
            return
        }

        cloudinary.createDownloader().fetchImage(url) { [weak self] (responseImage, error) in
            if let img = responseImage {
                DispatchQueue.main.async {
                    completion(responseImage?.jpegData(compressionQuality: 1), nil)
                }
            } else {
                completion(nil, .noData)
            }
        }

    }
}

