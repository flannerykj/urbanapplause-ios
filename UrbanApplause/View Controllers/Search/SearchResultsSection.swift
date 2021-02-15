//
//  SearchResult.swift
//  UrbanApplause
//
//  Created by Flann on 2021-02-13.
//  Copyright © 2021 Flannery Jefferson. All rights reserved.
//

import Foundation
import Shared
import UIKit

typealias SearchResultCellDelegate = PostCellDelegate

enum SearchResultSection {
    case posts([Post])
    case artists([Artist])
    case locations([Location])
    case groups([ArtistGroup])
    case collections([Collection])
    case users([User])
    
    static func registerCellClasses(forTableView tableView: UITableView) {
        for section in allCases {
            tableView.register(section.cellClass, forCellReuseIdentifier: section.cellIdentifier)
        }
    }
    
    func dequeueAndConfigureCell(tableView: UITableView, indexPath: IndexPath, appContext: AppContext, delegate: SearchResultCellDelegate?) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath)
        
        switch self {
        case .posts(let posts):
            let post = posts[indexPath.row]
            if let postCell = cell as? PostCell {
                postCell.post = post
                if let firstFile = post.PostImages?.first {
                    if let thumb = firstFile.thumbnail {
                        let imageJob = appContext.fileCache.getJobForFile(thumb, isThumb: true)
                        postCell.downloadJob = imageJob
                    } else {
                        let imageJob = appContext.fileCache.getJobForFile(firstFile, isThumb: true)
                        postCell.downloadJob = imageJob
                    }
                }
                postCell.appContext = appContext
                postCell.post = post
    //            cell.delegate = self
                postCell.indexPath = indexPath
                postCell.delegate = delegate
            }
            
        case .artists(let artists):
            let artist = artists[indexPath.row]
            cell.textLabel?.text = "Artist: \(artist.signing_name ?? "No name")"
            cell.imageView?.image = UIImage(systemName: "person.fill")
        case .locations(let locations):
            let location = locations[indexPath.row]
            cell.textLabel?.text = "Location: \(location.city ?? "No city")"
            cell.imageView?.image = UIImage(systemName: "mappin.and.ellipse")

        case .groups(let groups):
            let group = groups[indexPath.row]
            cell.textLabel?.text = "Artist Group: \(group.name)"
            cell.imageView?.image = UIImage(systemName: "person.3")

        case .collections(let collections):
            let collection = collections[indexPath.row]
            cell.textLabel?.text = "Collection: \(collection.title)"
            cell.imageView?.image = UIImage(systemName: "square.stack.3d.down.right")
        case .users(let users):
            let user = users[indexPath.row]
            cell.textLabel?.text = "User: \(user.username ?? "No username")"
            cell.imageView?.image = UIImage(systemName: "person.fill")
        }
        return cell
    }
    
    var title: String {
        switch self {
        case .artists:
            return "Artists"
        case .posts:
            return "Posts"
        case .locations:
            return "Places"
        case .groups:
            return "Artist Groups"
        case .collections:
            return "Collections"
        case .users:
            return "Users"
        }
    }
    
    var identifier: String {
        switch self {
        case .artists:
            return "artists"
        case .posts:
            return "posts"
        case .locations:
            return "locations"
        case .groups:
            return "artist_groups"
        case .collections:
            return "collections"
        case .users:
            return "users"
        }
    }
    
    // MARK: - Private
    
    private var cellIdentifier: String {
        switch self {
        case .artists:
            return "ArtistCell"
        case .posts(_):
            return "PostCell"

        case .locations(_):
            return "LocationCell"

        case .groups(_):
            return "ArtistGroupCell"

        case .collections(_):
            return "CollectionCell"

        case .users(_):
            return "UserCell"

        }
    }
    
    private var cellClass: AnyClass? {
        switch self {
        case .posts(_):
            return PostCell.self
        default:
            return UITableViewCell.self
        }
    }
    
    static var allCases: [SearchResultSection] {
        [.posts([]), .artists([]), .locations([]), .groups([]), .collections([]), .users([])]
    }
}
