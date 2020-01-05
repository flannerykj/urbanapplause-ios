//
//  APIRouter.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-08.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UrbanApplauseShared

enum PrivateRouter: EndpointConfiguration {
    // auth
    case authenticate(email: String, password: String, username: String?, newUser: Bool)
    
    // posts
    case getPosts(query: PostQuery)
    
    case getPost(id: Int)
    case getPostClusters(postedAfter: Date?, threshold: Double?, bounds: GeoBoundsFilter?)
    
    case createPost(values: [String: Any])
    case editPost(id: Int, values: Parameters)
    case deletePost(id: Int)
    
    // post images
    case deletePostImage(postId: Int, imageId: Int)
    case uploadImages(postId: Int, userId: Int, imagesData: [Data])
    case downloadImage(storage_location: String)
    
    // locations
    
    case getLocationPosts(locationId: Int)
    
    // user
    case getUser(id: Int)
    case createUser(values: Parameters)
    case updateUser(id: Int, values: Parameters)
    
    // artists
    case getArtists(query: Parameters?)
    case getArtist(artistId: Int)

    case createArtist(values: Parameters)
    
    // applause
    case addOrRemoveClap(postId: Int, userId: Int)
    case removeClap(clapId: Int)
    
    // visits
    case addOrRemoveVisit(postId: Int, userId: Int)
    case removeVisit(visitId: Int)
    
    // collections
    case getCollections(userId: Int?, postId: Int?)
    case createCollection(values: Parameters)
    case deleteCollection(id: Int)
    case updateCollection(id: Int, values: Parameters)
    case addToCollection(collectionId: Int, postId: Int, annotation: String)
    case deleteFromCollection(collectionId: Int, postId: Int)
    case updateCollectionPost(collectionId: Int, postId: Int, values: Parameters)
    
    // report issue with content
    case createPostFlag(postId: Int, reason: PostFlagReason)
    case createCommentFlag(commentId: Int, reason: PostFlagReason)
    case blockUser(blockingUserId: Int, blockedUserId: Int)
    
    // comments
    case getComments(postId: Int)
    case createComment(postId: Int, userId: Int, content: String)
    case deleteComment(commentId: Int)
    
    var baseURL: URL {
        return URL(string: "\(Config.apiEndpoint)/app")!
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .deletePost, .deletePostImage, .removeClap, .deleteCollection, .deleteFromCollection, .deleteComment:
            return .delete
        case .editPost, .updateUser, .updateCollection, .updateCollectionPost:
            return .put
        case .authenticate, .createPost, .createUser, .addOrRemoveClap, .addOrRemoveVisit, .createCollection,
             .addToCollection, .uploadImages, .createArtist, .createComment, .createPostFlag, .blockUser:
            return .post
        default:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .authenticate(_, _, _, let newUser):
            if newUser {
                return "register"
            }
            return "login"  
        case .getPosts, .createPost:
            return "posts"
        case .getPost(let id):
            return "posts/\(id)"
        case .getPostClusters:
            return "posts/clusters"
        case .editPost(let id, _), .deletePost(let id):
            return "posts/\(id)"
        case .uploadImages(let postId, _, _):
            return "posts/\(postId)/images"
        case .getUser(let userId), .updateUser(let userId, _):
            return "users/\(userId)"
        case .createUser:
            return "users"
        case .getArtists, .createArtist:
            return "artists"
        case .getArtist(let artistId):
            return "artists/\(artistId)"
        case .deletePostImage(let postId, let imageId):
            return "posts/\(postId)/images/\(imageId)"
        case .getLocationPosts(let locationId):
            return "locations/\(locationId)/posts"
        case .addOrRemoveClap:
            return "claps"
        case .removeClap(let id):
            return "claps/\(id)"
        case .addOrRemoveVisit:
            return "visits"
        case .removeVisit(let id):
            return "visits/\(id)"
        case .createCollection, .getCollections:
            return "collections"
        case .deleteCollection(let collectionId), .updateCollection(let collectionId, _):
            return "collections/\(collectionId)"
        case .addToCollection(let collectionId, _, _):
            return "collections/\(collectionId)/posts"
        case .deleteFromCollection(let collectionId, let postId),
             .updateCollectionPost(let collectionId, let postId, _):
            return "collections/\(collectionId)/posts/\(postId)"
        case .downloadImage(let filename):
            return "uploads/\(filename)"
        case .getComments(let postId), .createComment(let postId, _, _):
            return "posts/\(postId)/comments"
        case .deleteComment(let commentId):
            return "comments/\(commentId)"
        case .createPostFlag(let postId, _):
            return "posts/\(postId)/flags"
        case .createCommentFlag(let commentId, _):
        return "comments/\(commentId)/flags"
        case .blockUser:
            return "blocked_users"
        }
    }
    
    var task: HTTPTask {
        switch self {
        case .getCollections(let userId, let postId):
            var params = Parameters()
            if let id = userId {
                params["userId"] = String(id)
            }
            if let id = postId {
                params["postId"] = String(id)
            }
            return .requestParameters(bodyParameters: nil, urlParameters: params)
        case .authenticate(let email, let password, let username, _):
            let body: Parameters = ["user": ["email": email, "password": password, "username": username],
                                    "refresh_token": "true"] as [String: Any]
            return .requestParameters(bodyParameters: body, urlParameters: nil)
        case .getArtists(let queryParams):
            return .requestParameters(bodyParameters: nil, urlParameters: queryParams)
        case .getArtist:
            return .requestParameters(bodyParameters: nil, urlParameters: ["include": "posts"])
        case .createArtist(let values):
            return .requestParameters(bodyParameters: ["artist": values], urlParameters: nil)
        case .createPost(let values), .editPost(_, let values):
            return .requestParameters(bodyParameters: ["post": values], urlParameters: nil)
        case .createUser(let values), .updateUser(_, let values):
            return .requestParameters(bodyParameters: ["user": values], urlParameters: nil)
        case .createCollection(let values):
            return .requestParameters(bodyParameters: ["collection": values], urlParameters: nil)
        case .addToCollection(_, let postId, _):
            return .requestParameters(bodyParameters: ["PostId": postId], urlParameters: nil)
        case .addOrRemoveClap(let postId, let userId):
            return .requestParameters(bodyParameters: ["clap": ["PostId": postId, "UserId": userId]],
                                      urlParameters: nil)
        case .addOrRemoveVisit(let postId, let userId):
            return .requestParameters(bodyParameters: ["visit": ["PostId": postId, "UserId": userId]],
                                      urlParameters: nil)
        case .uploadImages(_, let userId, let imagesData):
            return .upload(fileKeyPath: "images[]", imagesData: imagesData, bodyParameters: ["UserId": userId])
        case .getPosts(let query):
            log.debug("query: \(query)")
            var params = Parameters()
            params["page"] = String(query.page)
            params["limit"] = String(query.limit)
            if let id = query.userId {
                params["userId"] = String(id)
            }
            if let id = query.applaudedBy {
                params["clappedBy"] = String(id)
            }
            if let id = query.visitedBy {
                params["visitedBy"] = String(id)
            }
            if let id = query.artistId {
                params["artistId"] = String(id)
            }
            if let searchQuery = query.search, searchQuery.count > 0 {
                params["search"] = searchQuery
            }
            if let id = query.collectionId {
                params["collectionId"] = String(id)
            }
            if let filter = query.proximity {
                params["lat"] = String(filter.target.latitude)
                params["lng"] = String(filter.target.longitude)
                params["max_distance"] = "\(filter.maxDistanceKm)"
            }
            if let bounds = query.bounds {
                params["lat1"] = String(bounds.neCoord.latitude)
                params["lng1"] = String(bounds.neCoord.longitude)
                params["lat2"] = String(bounds.swCoord.latitude)
                params["lng2"] = String(bounds.swCoord.longitude)
            }
            if query.include.count > 0 {
                params["include"] = query.include.joined(separator: ",")
            }
            return .requestParameters(bodyParameters: nil, urlParameters: params)
        case .getPostClusters(let postedAfter, let proximity, let geoBounds):
            var params = Parameters()
            if let bounds = geoBounds {
                params["lat1"] = String(bounds.neCoord.latitude)
                params["lng1"] = String(bounds.neCoord.longitude)
                params["lat2"] = String(bounds.swCoord.latitude)
                params["lng2"] = String(bounds.swCoord.longitude)
            }
            if let date = postedAfter {
                params["posted_after"] = String(date.timeIntervalSince1970)
            }
            if let threshold = proximity {
                params["threshold"] = String(threshold)
            }

            return .requestParameters(bodyParameters: nil, urlParameters: params)
        case .createComment(_, let userId, let content):
            return .requestParameters(bodyParameters: ["comment": [
                "UserId": userId,
                "content": content
                ]], urlParameters: nil)
        case .createPostFlag(_, let reason):
            return .requestParameters(bodyParameters: ["post_flag": [
                "user_reason": reason.rawValue
                ]], urlParameters: nil)
        case .createCommentFlag(_, let reason):
           return .requestParameters(bodyParameters: ["comment_flag": [
               "user_reason": reason.rawValue
               ]], urlParameters: nil)
        case .blockUser(let blockingUserId, let blockedUserId):
            return .requestParameters(bodyParameters: [
                "blocked_user": [
                    "BlockedUserId": blockedUserId,
                    "BlockingUserId": blockingUserId
                ]
            ], urlParameters: nil)
        default:
            return .request
        }
    }
    
    /* var query: Parameters? {
        switch self {
        case .getCollections(let query), .getPosts(let query):
            return query
        default:
            return nil
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .authenticate(let email, let password, _):
            return ["user": ["email": email, "password": password], "refresh_token": "true"] as [String : Any]
            
        case .createPost(let values), .createUser(let values), .editPost(_, let values), .updateUser(let values), .createCollection(let values):
            return values
        case .addApplause(let postId):
            return ["PostId": String(postId)]
        default:
            return nil
        }
    } */
    
    func getRequiredHeaders(keychainService: KeychainService) throws -> HTTPHeaders {
        var headers = HTTPHeaders()
        headers["Content-type"] = "application/json"
        do {
            let authTokens: AuthResponse =
                try keychainService.load(itemAt: KeychainItem.tokens.userAccount)
            headers["Authorization"] = "Bearer \(authTokens.access_token)"
        } catch {
            log.warning(error)
        }
        return headers
    }
}
