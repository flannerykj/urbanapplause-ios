//
//  TempImage.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

typealias JSON = [String: Any?]

public class TempImage {
    
    public let imgurId: String
    public let title: String
    public let link: NSURL?
    
    init(fromJson json: JSON) {
        imgurId = json["id"] as! String
        title = json["title"] as? String ?? ""
        let urlString = json["link"] as? String ?? ""
        link = NSURL(string: urlString)
    }
}
