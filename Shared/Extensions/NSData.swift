//
//  NSData.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-16.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation

public extension NSData {
    func getMimeType() -> String? {
        var values = [UInt8](repeating: 0, count: self.length)
        self.getBytes(&values, length: self.length)

        guard let firstByte = values.first else { return nil }
        switch firstByte {
        case 0xFF:
            return "image/jpeg"
        case 0x89:
            return "image/png"
        case 0x47:
            return "image/gif"
        // case 0x49:
        case 0x4D:
            return "image/tiff"
        default:
            return nil
        }
    }

}
public extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
