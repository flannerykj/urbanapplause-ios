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

public class ImageEXIFService {
    private var imageData: Data
    
    public init(data: Data) {
        self.imageData = data
    }
    
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
