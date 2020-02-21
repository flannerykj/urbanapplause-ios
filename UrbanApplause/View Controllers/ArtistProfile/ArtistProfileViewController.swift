//
//  ArtistProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

protocol ArtistProfileDelegate: AnyObject {
    
}

class ArtistProfileViewController: UIViewController {
    var appContext: AppContext
    var artist: Artist

    lazy var tabItems: [ToolbarTabItem] = {
        let postsViewModel = DynamicPostListViewModel(filterForArtist: artist, filterForQuery: nil,
                                                   appContext: appContext)
        let postsVC = PostListViewController(viewModel: postsViewModel, appContext: appContext)
        return [
            ToolbarTabItem(title: Strings.Artist_PostListTitle(artist.signing_name),
                           viewController: postsVC, delegate: self)
        ]
    }()
    
    init(artist: Artist, appContext: AppContext) {
        self.appContext = appContext
        self.artist = artist
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    lazy var nameLabel: UILabel = UILabel(type: .h8)
    lazy var bioLabel: UILabel = UILabel(type: .body)
    lazy var memberSinceLabel: UILabel = UILabel(type: .body)
    
    let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshUserProfile(sender:)), for: .valueChanged)
        control.backgroundColor = UIColor.backgroundMain
        return control
    }()

    lazy var headerTextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, bioLabel, memberSinceLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = 6
        return stackView
    }()
    
    lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerTextStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .top
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = StyleConstants.contentMargin
        return stackView
    }()
    
    lazy var tabsViewController = TabbedToolbarViewController(headerContent: headerStackView,
                                                              tabItems: self.tabItems,
                                                              appContext: appContext)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundMain
        navigationItem.title = artist.signing_name
        view.addSubview(tabsViewController.view!)
        tabsViewController.view!.fill(view: view)
        addChild(tabsViewController)
        tabsViewController.didMove(toParent: self)
        updateLabels()
    }
    
    @objc func refreshUserProfile(sender: UIRefreshControl) {
        let endpoint = PrivateRouter.getArtist(artistId: artist.id)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<ArtistContainer>) in
            
            DispatchQueue.main.async {
                sender.endRefreshing()
                switch result {
                case .success(let container):
                    self.artist = container.artist
                    self.updateLabels()
                case .failure(let error):
                    log.error(error)
                }
            }
        }
    }
    
    func updateLabels() {
        nameLabel.text = artist.signing_name
        if let bio = artist.bio, bio.count > 0 {
            bioLabel.isHidden = false
            bioLabel.text = bio
            bioLabel.font = TypographyStyle.body.font
        } else {
            bioLabel.isHidden = true
            bioLabel.font = TypographyStyle.placeholder.font
        }
        if let dateString = artist.createdAt?.justTheDate {
            memberSinceLabel.text = "\(Strings.ProfileCreatedOnFieldLabel) \(dateString)"
        }
    }
}

extension ArtistProfileViewController: ToolbarTabItemDelegate {
    
}

