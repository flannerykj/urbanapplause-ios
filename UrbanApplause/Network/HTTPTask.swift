//
//  HTTPTask.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

enum HTTPTask {
    case request
    case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters?)
    case requestParametersAndHeaders(bodyParameters: Parameters?,
                                    urlParameters: Parameters?,
                                    additionalHeaders: HTTPHeaders?)
    case download
    case upload(fileKeyPath: String, imagesData: [Data], bodyParameters: [String: Any])
}
