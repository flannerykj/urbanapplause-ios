//
//  HTTPTask.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

public enum HTTPTask {
    case request
    case requestParameters(bodyParameters: Parameters?, urlParameters: Parameters?)
    case requestParametersAndHeaders(bodyParameters: Parameters?,
                                    urlParameters: Parameters?,
                                    additionalHeaders: HTTPHeaders?)
    case download
    case upload(fileKeyPath: String, imagesData: [Data], bodyParameters: [String: Any])
}
