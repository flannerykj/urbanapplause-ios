//
//  CloudinaryService.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-10-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import Cloudinary

public enum CloudinaryError: Error {
    case invalidFilename
}
public class CloudinaryService {
    private let config = CLDConfiguration(cloudName: Config.cloudinaryCloudName, apiKey: Config.cloudinaryApiKey    )

    private let cloudName = Config.cloudinaryCloudName
    private let urlSession = URLSession(configuration: .default)
    public init() {
        
    }
    
    public func downloadFile(filename: String,
                      updateProgress: @escaping (Double) -> Void,
                      completion: @escaping (Data?, Error?) -> Void) {
        guard let url = URL(string: "") else {
            completion(nil, CloudinaryError.invalidFilename)
            return
        }
        let request = URLRequest(url: url)
        urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, .custom(error))
                return
            }
            guard let data = data else {
                completion(nil, RemoteImageError.downloadError(nil))
                return
            }
            
            completion(data, nil)
        }
    }
}
