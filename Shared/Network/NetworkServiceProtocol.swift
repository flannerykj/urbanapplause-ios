//
//  NetworkServiceProtocol.swift
//  Shared
//
//  Created by Flannery Jefferson on 2020-01-09.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation

fileprivate let log = DHLogger.self

public protocol NetworkServiceProtocol: NSObject {
    func onReceiveAccessDeniedError(error: UAServerError)
    func getCustomHeaders() -> [String: String]
    var session: URLSession { get set }
}

public extension NetworkServiceProtocol {
    
    var requestTimeoutInterval: Double {
        return 60
    }
    
    var sessionConfig: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeoutInterval
        config.timeoutIntervalForResource = requestTimeoutInterval
        return config
    }
    
    func handleResponse<T>(data: Data?,
                           response: URLResponse?,
                           error: Error?) -> UAResult<T> where T: Decodable {
        
        if let error = self.handleError(data: data, response: response, error: error) {
            log.error("error: \(error.debugMessage)")
            if let serverError = error as? UAServerError {
                switch serverError.name {
                case .AccessDeniedError:
                    DispatchQueue.main.async {
                        self.onReceiveAccessDeniedError(error: serverError)
                    }
                default: break
                }
            }
            return UAResult.failure(error)
        }
        // DEV
        do {
            if let data = data,
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                log.verbose(["json: ", json])
            }
        } catch {}
        if let data = data as? T { // requested format is Data
            
            return UAResult.success(data)
            
        } else { // decode to requested type
            do {
                guard let data = data else { return UAResult.failure(NetworkError.dataNotFound) }
                log.debug("did decode")
                let decodedObject = try self.decoder.decode(T.self, from: data)
                return UAResult.success(decodedObject)
            } catch let error {
                log.error(error)
                return .failure(NetworkError.decodingError(error: error))
            }
        }
    }
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let strategy = JSONDecoder.DateDecodingStrategy.createStrategy(acceptedDateFormats: Date.Format.allCases)
        decoder.dateDecodingStrategy = strategy
        return decoder
    }
    
    // Helper methods
    func handleError(data: Data?, response: URLResponse?, error: Error?) -> UAError? {
        if error?._code == -1001 {
            //Domain=NSURLErrorDomain Code=-1001 "The request timed out."
            return NetworkError.requestTimeout
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            log.error(error as Any)
            return NetworkError.noResponse
        }
        guard let data = data else {
            return NetworkError.dataNotFound
        }
        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            log.verbose(["json: ", json])
        }
        if let errorWrapper = try? JSONDecoder().decode(ServerErrorWrapper.self, from: data) {
            return errorWrapper.error
        }
        switch httpResponse.statusCode {
        case 200..<300: return nil
        case 401:
            return UAServerError(name: .AccessDeniedError, message: "Access denied", code: nil)
        case 404:
            return NetworkError.fourOhFour
        default:
            return NetworkError.invalidCode(code: httpResponse.statusCode)
        }
    }
    
    func buildRequest(from route: EndpointConfiguration) throws -> URLRequest {
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: requestTimeoutInterval)
        
        request.httpMethod = route.httpMethod.rawValue
        do {
            try addHeaders(headers: self.getCustomHeaders(),
                           to: &request)
            
            switch route.task {
            case .request:
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .requestParameters(let bodyParameters, let urlParameters):
                try self.configureParameters(bodyParameters: bodyParameters,
                                             urlParameters: urlParameters,
                                             request: &request)
            case .requestParametersAndHeaders(let bodyParameters, let urlParameters, let additionalHeaders):
                try self.addHeaders(headers: additionalHeaders ?? HTTPHeaders(), to: &request)
                try self.configureParameters(bodyParameters: bodyParameters,
                                             urlParameters: urlParameters,
                                             request: &request)
            case .upload(let fileKeyPath, let imagesData, let bodyParameters):
                let boundary = "Boundary-\(UUID().uuidString)"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.httpBody = createFormDataBody(filePathKey: fileKeyPath,
                                                      boundary: boundary,
                                                      imagesData: imagesData,
                                                      bodyParameters: bodyParameters)
            default:
                break
            }
            return request
            
        } catch {
            log.error(error)
        }
        return request
    }
    
    func addHeaders(headers: HTTPHeaders, to request: inout URLRequest) throws {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    func configureParameters(bodyParameters: Parameters?,
                             urlParameters: Parameters?,
                             request: inout URLRequest) throws {
        do {
            if let bodyParameters = bodyParameters {
                try JSONParameterEncoder.encode(urlRequest: &request, with: bodyParameters)
            }
            if let urlParameters = urlParameters {
                try URLParamterEncoder.encode(urlRequest: &request, with: urlParameters)
            }
        } catch {
            log.error(error)
            throw error
        }
    }
    
    func createFormDataBody(filePathKey: String,
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
            let mimeType = data.getMimeType() ?? ""
            body.appendString(string: boundaryPrefix)
            body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.appendString(string: "Content-Type: \(mimeType)\r\n\r\n")
            body.append(data)
            body.appendString(string: "\r\n")
            body.appendString(string: "--".appending(boundary.appending("--")))
        }
        return body as Data
    }
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}
