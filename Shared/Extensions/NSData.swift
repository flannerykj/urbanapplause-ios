//
//  NSData.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-16.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public extension Data {
    func getMimeType() -> String? {
        var b: UInt8 = 0
        self.copyBytes(to: &b, count: 1)

        switch b {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        case 0x4D, 0x49:
            return "image/tiff"
        case 0x25:
            return "application/pdf"
        case 0xD0:
            return "application/vnd"
        case 0x46:
            return "text/plain"
        default:
            return "application/octet-stream"
        }
    }

}
public extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
