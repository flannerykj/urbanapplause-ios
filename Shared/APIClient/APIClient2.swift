//
//  APIClient2.swift
//  Shared
//
//  Created by Flann on 2021-02-16.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Combine

fileprivate let log = DHLogger.self

public class EndpointConfigurationV2: EndpointConfiguration {
    public var baseURL: URL
    public var httpMethod: HTTPMethod
    public var path: String
    public var task: HTTPTask
    public var headers: [String: String]
    
    
    public init(baseURL: URL, httpMethod: HTTPMethod, path: String, task: HTTPTask, headers: [String: String] = [:]) {
        self.baseURL = baseURL
        self.httpMethod = httpMethod
        self.path = path
        self.task = task
        self.headers = headers
    }
}

public class UAAPIEndpointConfig: EndpointConfigurationV2 {
    
    public init(httpMethod: HTTPMethod, path: String, task: HTTPTask, headers: [String: String] = [:]) {
        super.init(baseURL: URL(string: Config.apiEndpoint)!, httpMethod: httpMethod, path: path, task: task, headers: headers)
    }
}

public protocol NetworkServiceV2: AnyObject {
    func request<T>(_ route: EndpointConfigurationV2, priority: NetworkServiceJobPriority) -> AnyPublisher<T, Error> where T: Decodable
}

public class APIClientV2: NSObject, NetworkServiceV2 {
    private var session: URLSession = .shared
    private let onReceiveAuthError: (Error) -> ()
    private let getCustomHeaders: () -> [String: String]
    
    public init(getCustomHeaders: @escaping () -> [String: String],
                onReceiveAuthError: @escaping (Error) -> ()) {
        self.getCustomHeaders = getCustomHeaders
        self.onReceiveAuthError = onReceiveAuthError
    }
    
    // MARK: - APIClient2
    
    public func request<T>(_ route: EndpointConfigurationV2, priority: NetworkServiceJobPriority = .primary) -> AnyPublisher<T, Error> where T: Decodable {
        do {
            var request = try self.buildRequest(from: route)
            try addHeaders(headers: getCustomHeaders(), to: &request)
            
            return self.session.dataTaskPublisher(for: request)
                .tryMap { data, response in
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.noResponse
                    }
                    
                    switch httpResponse.statusCode {
                    case 200..<300:
                        return try self.decoder.decode(T.self, from: data) // Success
                    case 401:
                        let error = UAServerError(name: .AccessDeniedError, message: "Access denied", code: nil)
                        self.onReceiveAuthError(error)
                        throw error
                    case 404:
                        throw NetworkError.fourOhFour
                    default:
                        throw NetworkError.invalidCode(code: httpResponse.statusCode)
                    }
                }
                .subscribe(on: priority.scheduler)
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            log.error(error)
            return Fail(outputType: T.self, failure: error)
                .eraseToAnyPublisher()
        }
    }
    
    // MARK: - Private
    
    private var requestTimeoutInterval: Double {
        return 60
    }
    
    private var sessionConfig: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeoutInterval
        config.timeoutIntervalForResource = requestTimeoutInterval
        return config
    }
    
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let strategy = JSONDecoder.DateDecodingStrategy.createStrategy(acceptedDateFormats: Date.Format.allCases)
        decoder.dateDecodingStrategy = strategy
        return decoder
    }
    
    private func buildRequest(from route: EndpointConfigurationV2) throws -> URLRequest {
        var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                 cachePolicy: .useProtocolCachePolicy,
                                 timeoutInterval: requestTimeoutInterval)
        
        request.httpMethod = route.httpMethod.rawValue
        do {
            try addHeaders(headers: route.headers,
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
    
    private func addHeaders(headers: HTTPHeaders, to request: inout URLRequest) throws {
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    private func configureParameters(bodyParameters: Parameters?,
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
    
    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}


fileprivate extension NetworkServiceJobPriority {
    var scheduler: DispatchQueue {
        switch self {
        case .primary:
            return DispatchQueue(label: "com.urbanapplause.network_primary", qos: .utility, target: .global())
        case .secondary:
            return DispatchQueue(label: "com.urbanapplause.network_secondary", qos: .background, target: .global())
        }
    }
}
