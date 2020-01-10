//
//  ImageService.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import MapKit

public class ImageService {
    private var imageData: Data
    
    public init(data: Data) {
        self.imageData = data
    }
    internal let DEFAULT_MIME_TYPE = "application/octet-stream"
    
    public var placemarkFromExif: CLPlacemark? {
        let source: CGImageSource = CGImageSourceCreateWithData((self.imageData as! CFMutableData), nil)!
        guard let dict = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let gpsData = dict[kCGImagePropertyGPSDictionary] as? [CFString: Any],
            var longitude = gpsData[kCGImagePropertyGPSLongitude] as? Double,
            var latitude = gpsData[kCGImagePropertyGPSLatitude] as? Double,
            let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef] as? String,
            let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef] as? String else {
                return nil
        }
        if longitudeRef == "W" {
            longitude *= -1
        }
        if latitudeRef == "S" {
            latitude *= -1
        }
        guard let latitudeDegrees = CLLocationDegrees(exactly: latitude),
            let longitudeDegrees = CLLocationDegrees(exactly: longitude) else {
                return nil
        }
            
        var addressDictionary: [String: String] = [:]
        if let iptcData = dict[kCGImagePropertyIPTCDictionary] as? [CFString: Any] {
            
            if let country = iptcData[kCGImagePropertyIPTCCountryPrimaryLocationName] as? String {
                addressDictionary["country"] = country
            }
            
            if let city = iptcData[kCGImagePropertyIPTCCity] as? String {
                addressDictionary["city"] = city
            }
        }
        return MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitudeDegrees,
                                                                       longitude: longitudeDegrees),
                           addressDictionary: addressDictionary) as CLPlacemark
    }
    
    public var dateFromExif: Date? {
        let source: CGImageSource = CGImageSourceCreateWithData((imageData as! CFMutableData), nil)!
        guard let dict = CGImageSourceCopyPropertiesAtIndex(source, 0,nil) as? [CFString: Any],
            let tiffData = dict[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
            let dateTimeString = tiffData[kCGImagePropertyTIFFDateTime] as? String else {
                return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return dateFormatter.date(from: dateTimeString)
    }
    public static func mimeType(for data: Data) -> String {
        var b: UInt8 = 0
        data.copyBytes(to: &b, count: 1)

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

    internal let mimeTypes = [
        "html": "text/html",
        "htm": "text/html",
        "shtml": "text/html",
        "css": "text/css",
        "xml": "text/xml",
        "gif": "image/gif",
        "jpeg": "image/jpeg",
        "jpg": "image/jpeg",
        "js": "application/javascript",
        "atom": "application/atom+xml",
        "rss": "application/rss+xml",
        "mml": "text/mathml",
        "txt": "text/plain",
        "jad": "text/vnd.sun.j2me.app-descriptor",
        "wml": "text/vnd.wap.wml",
        "htc": "text/x-component",
        "png": "image/png",
        "tif": "image/tiff",
        "tiff": "image/tiff",
        "wbmp": "image/vnd.wap.wbmp",
        "ico": "image/x-icon",
        "jng": "image/x-jng",
        "bmp": "image/x-ms-bmp",
        "svg": "image/svg+xml",
        "svgz": "image/svg+xml",
        "webp": "image/webp",
        "woff": "application/font-woff",
        "jar": "application/java-archive",
        "war": "application/java-archive",
        "ear": "application/java-archive",
        "json": "application/json",
        "hqx": "application/mac-binhex40",
        "doc": "application/msword",
        "pdf": "application/pdf",
        "ps": "application/postscript",
        "eps": "application/postscript",
        "ai": "application/postscript",
        "rtf": "application/rtf",
        "m3u8": "application/vnd.apple.mpegurl",
        "xls": "application/vnd.ms-excel",
        "eot": "application/vnd.ms-fontobject",
        "ppt": "application/vnd.ms-powerpoint",
        "wmlc": "application/vnd.wap.wmlc",
        "kml": "application/vnd.google-earth.kml+xml",
        "kmz": "application/vnd.google-earth.kmz",
        "7z": "application/x-7z-compressed",
        "cco": "application/x-cocoa",
        "jardiff": "application/x-java-archive-diff",
        "jnlp": "application/x-java-jnlp-file",
        "run": "application/x-makeself",
        "pl": "application/x-perl",
        "pm": "application/x-perl",
        "prc": "application/x-pilot",
        "pdb": "application/x-pilot",
        "rar": "application/x-rar-compressed",
        "rpm": "application/x-redhat-package-manager",
        "sea": "application/x-sea",
        "swf": "application/x-shockwave-flash",
        "sit": "application/x-stuffit",
        "tcl": "application/x-tcl",
        "tk": "application/x-tcl",
        "der": "application/x-x509-ca-cert",
        "pem": "application/x-x509-ca-cert",
        "crt": "application/x-x509-ca-cert",
        "xpi": "application/x-xpinstall",
        "xhtml": "application/xhtml+xml",
        "xspf": "application/xspf+xml",
        "zip": "application/zip",
        "bin": "application/octet-stream",
        "exe": "application/octet-stream",
        "dll": "application/octet-stream",
        "deb": "application/octet-stream",
        "dmg": "application/octet-stream",
        "iso": "application/octet-stream",
        "img": "application/octet-stream",
        "msi": "application/octet-stream",
        "msp": "application/octet-stream",
        "msm": "application/octet-stream",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "mid": "audio/midi",
        "midi": "audio/midi",
        "kar": "audio/midi",
        "mp3": "audio/mpeg",
        "ogg": "audio/ogg",
        "m4a": "audio/x-m4a",
        "ra": "audio/x-realaudio",
        "3gpp": "video/3gpp",
        "3gp": "video/3gpp",
        "ts": "video/mp2t",
        "mp4": "video/mp4",
        "mpeg": "video/mpeg",
        "mpg": "video/mpeg",
        "mov": "video/quicktime",
        "webm": "video/webm",
        "flv": "video/x-flv",
        "m4v": "video/x-m4v",
        "mng": "video/x-mng",
        "asx": "video/x-ms-asf",
        "asf": "video/x-ms-asf",
        "wmv": "video/x-ms-wmv",
        "avi": "video/x-msvideo"
    ]

    internal func mimeType(_ ext: String?) -> String {
        if ext != nil && mimeTypes.contains(where: { $0.0 == ext!.lowercased() }) {
            return mimeTypes[ext!.lowercased()]!
        }
        return DEFAULT_MIME_TYPE
    }
}

//extension NSURL {
//    public func mimeType() -> String {
//        return ImageService().mimeType(self.pathExtension)
//    }
//}
//
//extension NSString {
//    public func mimeType() -> String {
//        return ImageService().mimeType(self.pathExtension)
//    }
//}
//
//extension String {
//    public func mimeType() -> String {
//        return (self as NSString).mimeType()
//    }
//}
