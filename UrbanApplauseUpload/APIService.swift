//
//  NetworkService.swift
//  UrbanApplauseUpload
//
//  Created by Flannery Jefferson on 2020-01-06.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

enum APIServiceError: Error, UAError {
    case noData, errorCreatingPost(Error), errorDecodingPost(Error)
    
    var userMessage: String {
        return "Error posting to server"
    }
    
    var debugMessage: String {
        return self.userMessage
    }
    var errorCode: UAErrorCode? {
        return nil
    }
}
class APIService {
    var keychainService: KeychainService
    let baseURL = URL(string: Config.apiEndpoint)!.appendingPathComponent("/app")

    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    public func shareImage(_ imageData: Data,
                      withMetaData postMetaData: [String: Any],
                      onCreatePost: @escaping () -> Void,
                      imageUploadDelegate: URLSessionDelegate,
                      onError: @escaping (APIServiceError) -> Void) {
        
        self.createPost { data, response, error in
            if let error = error {
                onError(.errorCreatingPost(error))
                return
            }
            guard let data = data else {
                onError(.noData)
                return
            }
            let decoder = JSONDecoder()
            do {
                let postId = try decoder.decode(PostContainer.self, from: data).post.id
                onCreatePost()
                self.uploadImages(postId: postId,
                                             imagesData: [imageData],
                                             delegate: imageUploadDelegate)
            } catch {
                onError(.errorDecodingPost(error))
            }
        }
        
    }
    private func createPost(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
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
            
        let session = URLSession(configuration: config, delegate: nil, delegateQueue: OperationQueue.main)
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


    private func uploadImages(postId: Int, imagesData: [Data], delegate: URLSessionDelegate?) {
        
        let authTokens: AuthResponse =
            try! keychainService.load(itemAt: KeychainItem.tokens.userAccount)
        let headers: [String: String] = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authTokens.access_token)"
        ]
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.urbanapplause.ios.bkgrdsession")
        config.sharedContainerIdentifier = "com.urbanapplause.ios"
        config.httpAdditionalHeaders = headers
            
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: OperationQueue.main)
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

}
