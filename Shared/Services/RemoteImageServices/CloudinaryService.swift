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
    private let config = CLDConfiguration(cloudName: Config.cloudinaryCloudName, apiKey: Config.cloudinaryApiKey, secure: true)
    private let cloudinary: CLDCloudinary
    
    public init() {
        cloudinary = CLDCloudinary(configuration: config)
    }
    
    public func downloadFile(filename: String,
                             updateProgress: @escaping (Double) -> Void,
                             completion: @escaping (Data?, RemoteImageError?) -> Void) {
        
//        guard let url = URL(string: "https://\(Config.cloudinaryApiKey):\(Config.cloudinaryApiSecret)@api.cloudinary.com/v1_1/\(Config.cloudinaryCloudName)/resources/image") else {
//            completion(nil, RemoteImageError.invalidFilename)
//            return
//        }
//        print(url)
//        let request = URLRequest(url: url)
//        let session = URLSession(configuration: .default)
//        let task = session.dataTask(with: request, completionHandler: { data, response, error in
//            guard let d = data else {
//                completion(nil, .noData)
//                return
//            }
//            guard error == nil else {
//                completion(nil, .custom(error))
//                return
//            }
//            completion(d, nil)
//        })
//
//        task.resume()
        
        let url = cloudinary.createUrl().setFormat("png").setResourceType("image").generate(filename)!
        cloudinary.createDownloader().fetchImage(url, { progress in
            
        }, completionHandler: { image, error in
            
        }).resume()


    }
}

