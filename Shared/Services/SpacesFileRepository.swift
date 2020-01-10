//
//  SpacesFileRepository.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-11-19.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

// Adapted from https://github.com/br3nt0n/Digital-Ocean-Spaces-iOS-Example/tree/master/Digital%20Ocean%20Spaces%20Example

import Foundation
import AWSS3

fileprivate let log = DHLogger.self

public enum S3Error: UAError {
    case uploadError(String?), downloadError(String?)
    
    public var errorCode: UAErrorCode? { return nil }
    
    public var debugMessage: String {
        switch self {
        case .uploadError(let string):
            return string ?? "Unable to upload file"
        case .downloadError(let string):
            return string ?? "Unable to download file"
        }
    }
    
    public var userMessage: String {
        switch self {
        case .uploadError(let string):
            return string ?? "Unable to upload file"
        case .downloadError(let string):
            return string ?? "Unable to download file"
        }
    }
}

public struct SpacesFileRepository {
    private static let accessKey = Config.awsAccessKeyId
    private static let secretKey = Config.awsSecretAccessKey
    private static let bucket = Config.awsBucketName // name of space
    private static let endpointUrl = "https://nyc3.digitaloceanspaces.com"
    private var transferUtility: AWSS3TransferUtility?
    
    public init() {
        let credential = AWSStaticCredentialsProvider(accessKey: SpacesFileRepository.accessKey,
                                                      secretKey: SpacesFileRepository.secretKey)
        
        let regionEndpoint = AWSEndpoint(urlString: SpacesFileRepository.endpointUrl)
        
        let configuration = AWSServiceConfiguration(region: .USEast1,
                                                    endpoint: regionEndpoint, // TODO -set region
                                                    credentialsProvider: credential)
        
        // configuration to point to DO space.
        let transferConfiguration = AWSS3TransferUtilityConfiguration()
        transferConfiguration.isAccelerateModeEnabled = false
        transferConfiguration.bucket = SpacesFileRepository.bucket
        
        AWSS3TransferUtility.register(with: configuration!,
                                      transferUtilityConfiguration: transferConfiguration,
                                      forKey: SpacesFileRepository.bucket)
        transferUtility = AWSS3TransferUtility.s3TransferUtility(forKey: SpacesFileRepository.bucket)
        
        
    }
    
    /* func uploadFileData(_ data: Data, completion: @escaping (UAResult<String>) -> Void) {
        let mimeType = ImageService.mimeType(for: data)
        let expression = AWSS3TransferUtilityUploadExpression()
        let filename = UUID().uuidString
        transferUtility?.uploadData(data,
                                    key: "uploads/\(filename)", contentType: mimeType,
                                    expression: expression,
                                    completionHandler: { task, error in
            guard error == nil else {
                log.debug("S3 Upload Error: \(error!.localizedDescription)")
                completion(.failure(S3Error.uploadError(error?.localizedDescription)))
                return
            }
            }).continueWith(block: { (task) -> Any? in
                // start the upload task
                log.debug("S3 Upload Starting")
                return nil
            }).continueOnSuccessWith(block: { task in
                completion(.success(filename))
            })
    } */
    
    public func downloadFile(filename: String,
                      updateProgress: @escaping (Double) -> Void,
                      completion: @escaping (Data?, Error?) -> Void) {
        
        let expression = AWSS3TransferUtilityDownloadExpression()
        expression.progressBlock = { result, progress in
            updateProgress(progress.fractionCompleted)
        }
        
        transferUtility?.downloadData(forKey: "uploads/\(filename)", expression: expression, completionHandler: { (task, url, data, error) in
            guard error == nil else {
                log.error("S3 Download Error: \(error!.localizedDescription)")
                completion(nil, error)
                return
            }
            completion(data, nil)
        }).continueWith(block: { (task) -> Any? in
            // start the download task
            return nil
        })
    }
}