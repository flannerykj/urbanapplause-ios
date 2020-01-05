//
//  ShareViewController.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-03.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import UIKit
import Social
import MobileCoreServices
import Photos

enum HTTPMethod: String {
    case get, put, post, delete
}

class ShareViewController: SLComposeServiceViewController {
    /*let baseURL = URL(string: Config.apiEndpoint)!.appendingPathComponent("/app")
    let currentDate = Date()
    let keychainService = KeychainService()
    var imageDate: Date?
    var selectedImage: UIImage? {
        didSet {
            if let photo = selectedImage as? PHAsset {
                photo.requestContentEditingInput(with: nil, completionHandler: { input, _ in
                    DispatchQueue.main.async {
                        if let uniformTypeIdentifier = input?.uniformTypeIdentifier {
                            print("type: \(uniformTypeIdentifier)")
                            if uniformTypeIdentifier == "public.heic" {
                                
                            }
                        }
                        if let url = input?.fullSizeImageURL, let fullImage = CIImage(contentsOf: url) {
                            let properties = fullImage.properties
                            self.imageDate = self.getDateFromExif(properties)
                            /*if let locationRow = self.form.rowBy(tag: "location") as? LocationRow,
                                let placemark = getPlacemarkFromExif(properties) {
                                
                                guard let location = placemark.location else { return }
                                
                                CLGeocoder().reverseGeocodeLocation(location,
                                                                    completionHandler: { (placemarks, _) in
                                                                        if let placemarkWithInfo = placemarks?.first {
                                                                            DispatchQueue.main.async {
                                                                                
                                                                            }
                                                                        }
                                })
                            }*/
                        }
                    }
                })
            }
        }
    }
    
    override func isContentValid() -> Bool {
        guard self.isAuthenticated else { print("NOT AUTHE!"); return false }
        if selectedImage != nil {
            if !contentText.isEmpty {
                return true
            }
        }
        print("INvalid content selected!!!!")
        return false
    }
    
    struct Post: Decodable {
        var id: Int
    }

    struct AuthResponse: Codable {
        var access_token: String
        var refresh_token: String?
        var user: User?
    }
    
    struct User: Codable {
        var id: Int
    }

    struct PostContainer: Decodable {
        var post: Post
    }
    override func didSelectPost() {
        print("BASE URL: \(self.baseURL)")
        createPost { data, response, error in
            guard error == nil else {
                print("ERROR: \(error)")
                return
            }
            guard let data = data else {
                print("no data")
                return
            }
            let decoder = JSONDecoder()
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print(["json: ", json])
                }
                let postId = try decoder.decode(PostContainer.self, from: data).post.id
                self.uploadImages(postId: postId, imagesData: [self.selectedImage!.jpegData(compressionQuality: 0.7)!])
                self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            } catch {
                print(error)
            }
        }
    }
    func createPost(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let authData: AuthResponse =
            try! keychainService.load(itemAt: KeychainItem.tokens.userAccount)
        let userId = authData.user!.id
        let body: [String:Any] = [
            "post": [
                "UserId": 1,
                "location": [
                    "coordinates": [
                        "latitude": 1,
                        "longitude": 2
                    ]
                ]
            ]
        ]

        let headers: [String: String] = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authData.access_token)"
        ]
        
        let config = URLSessionConfiguration.default
        config.sharedContainerIdentifier = "com.urbanapplause.ios"
        config.httpAdditionalHeaders = headers
            
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        let timeoutInterval: TimeInterval = 500
        let url = baseURL.appendingPathComponent("posts")
        print("URL: \(url.absoluteString)")
        var request = URLRequest(url: url,
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonData
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        } catch {
            print(error)
        }
        let task = session.dataTask(with: request) { data, response, error in
            completion(data, response, error)
        }
        task.resume()
    }


    func uploadImages(postId: Int, imagesData: [Data]) {
        
        let authTokens: AuthResponse =
            try! keychainService.load(itemAt: KeychainItem.tokens.userAccount)
        let headers: [String: String] = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authTokens.access_token)"
        ]
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.urbanapplause.ios.bkgrdsession")
        config.sharedContainerIdentifier = "com.urbanapplause.ios"
        config.httpAdditionalHeaders = headers
            
        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
        let userId = authTokens.user!.id
        let timeoutInterval: TimeInterval = 500
        
        var request = URLRequest(url: baseURL.appendingPathComponent("posts"),
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.url = baseURL.appendingPathComponent("posts/\(postId)/images")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createFormDataBody(filePathKey: "images[]",
                                              boundary: boundary,
                                              imagesData: imagesData,
                                              bodyParameters: ["UserId": userId])
        
        let task = session.dataTask(with: request)
        task.resume()
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
    
    override func viewDidLoad() {
            
        super.viewDidLoad()
            
        let content = extensionContext!.inputItems[0] as! NSExtensionItem
        let contentType = kUTTypeImage as String
            
        for attachment in content.attachments as! [NSItemProvider] {
            if attachment.hasItemConformingToTypeIdentifier(contentType) {
                        
                attachment.loadItem(forTypeIdentifier: contentType, options: nil) { data, error in
                    if error == nil {
                        let url = data as! NSURL
                        if let imageData = NSData(contentsOf: url as URL) {
                            self.selectedImage = UIImage(data: imageData as Data)
                        }
                    } else {
                            
                        let alert = UIAlertController(title: "Error", message: "Error loading image", preferredStyle: .alert)
                            
                        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
                            self.dismiss(animated: true, completion: nil)
                        }
                            
                        alert.addAction(action)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    private func createFormDataBody(filePathKey: String,
                                    boundary: String,
                                    imagesData: [Data],
                                    bodyParameters: [String: Any]) -> Data {
        let body = NSMutableData()

        let boundaryPrefix = "--\(boundary)\r\n"

        for (key, value) in bodyParameters {
            body.appendString(string: boundaryPrefix)
            body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString(string: "\(value)\r\n")
        }

        for data in imagesData {
            let filename = UUID().uuidString
            let mimeType = ""
            body.appendString(string: boundaryPrefix)
            body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.appendString(string: "Content-Type: \(mimeType)\r\n\r\n")
            body.append(data)
            body.appendString(string: "\r\n")
            body.appendString(string: "--".appending(boundary.appending("--")))
        }
        return body as Data
    }

    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    public var isAuthenticated: Bool {
        do {
            let tokens: AuthResponse = try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            print("tokens: \(tokens)")
            let decoded = decode(jwtToken: tokens.access_token)
            print("decoded: \(decoded)")
            guard let seconds = decoded["exp"] as? Double else {
                print("expiry \(decoded["exp"] ?? "no expiry value")")
                return false
            }
            let expiryDate = Date(timeIntervalSince1970: seconds)
            print("expiry date: \(expiryDate)")
            return expiryDate > self.currentDate
        } catch {
            print("ERROR: \(error)")
            return false
        }
    }
    
    private func decode(jwtToken jwt: String) -> [String: Any] {
      let segments = jwt.components(separatedBy: ".")
      return decodeJWTPart(segments[1]) ?? [:]
    }

    private func base64UrlDecode(_ value: String) -> Data? {
      var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")

      let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
      let requiredLength = 4 * ceil(length / 4.0)
      let paddingLength = requiredLength - length
      if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
      }
      return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }

    private func decodeJWTPart(_ value: String) -> [String: Any]? {
      guard let bodyData = base64UrlDecode(value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []),
        let payload = json as? [String: Any] else {
          return nil
      }
      return payload
    }
    
    func getDateFromExif(_ exifProperties: [String: Any]) -> Date? {
        if let tiffData = exifProperties["{TIFF}"] as? [String: Any] {
            if let dateTime = tiffData["DateTime"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                let date = dateFormatter.date(from: dateTime)
                return date
            }
        }
        return nil
    }

}
extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    } */
}
extension ShareViewController: URLSessionDelegate {
    
}
