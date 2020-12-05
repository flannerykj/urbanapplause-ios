//
//  ArtistListViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import CoreLocation
import Shared
import UIKit

protocol ArtistListControllerDelegate: class {
    var canEditArtists: Bool { get }
    func didDeleteArtist(_ artist: Artist, atIndexPath indexPath: IndexPath)
}

class ArtistListViewController: UIViewController {
    var contentHeight: CGFloat {
        return self.tableView.contentSize.height
    }
    weak var tabContentDelegate: TabContentDelegate?
    let tableHeaderHeight: CGFloat = 80
    let tableFooterHeight: CGFloat = 80
    let sectionHeaderHeight: CGFloat = 60
    
    var query: String?
    var appContext: AppContext
    var viewModel: ArtistListViewModel
    var backgroundColor = UIColor.systemGray6
    var tableContentHeight: CGFloat = 0
    weak var artistListDelegate: ArtistListControllerDelegate?
    let LEFT_EDITING_MARGIN: CGFloat = 12
    var listTitle: String?
    var requestOnLoad: Bool
    var lastCellHeight: CGFloat = 0
    
    init(listTitle: String? = nil,
         viewModel: ArtistListViewModel,
         requestOnLoad: Bool = true,
         appContext: AppContext) {
        
        self.appContext = appContext
        self.viewModel = viewModel
        self.listTitle = listTitle
        self.requestOnLoad = requestOnLoad
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let refreshControl = UIRefreshControl()
    
    let tableHeaderLabel = UILabel(type: .body)
    
    lazy var tableHeaderView: UIView = {
       tableHeaderLabel.textAlignment = .center
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: tableHeaderHeight))
        view.addSubview(tableHeaderLabel)
        tableHeaderLabel.fill(view: view)
        return view
    }()
    
    lazy var loadMoreButton = UAButton(type: .link,
                                       title: Strings.LoadMoreArtistsButtonTitle,
                                       target: self,
                                       action: #selector(pressedLoadMoreArtists(_:)))
    
    let loadMoreSpinner = ActivityIndicator()

    lazy var tableFooterView: UIView = {
        loadMoreButton.setTitle(Strings.LoadMoreArtistsButtonTitle, for: .normal)
        loadMoreButton.addTarget(self, action: #selector(pressedLoadMoreArtists(_:)), for: .touchUpInside)
        loadMoreButton.titleLabel?.textAlignment = .center
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: tableFooterHeight))
        view.addSubview(loadMoreButton)
        view.addSubview(loadMoreSpinner)
        NSLayoutConstraint.activate([
            loadMoreButton.rightAnchor.constraint(equalTo: view.rightAnchor),
            loadMoreButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            loadMoreButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            loadMoreSpinner.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            loadMoreSpinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
       return view
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ArtistCell.self, forCellReuseIdentifier: "ArtistCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        tableView.backgroundColor = backgroundColor
        tableView.separatorStyle = .none
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMoreSpinner.hidesWhenStopped = true
        view.addSubview(tableView)
        tableView.fill(view: self.view)
        tableView.refreshControl = refreshControl
        
        view.backgroundColor = backgroundColor
        
        viewModel.didUpdateListItems = { addedIndexPaths, removedIndexPaths, shouldReload in
            DispatchQueue.main.async {
                if shouldReload {
                    self.tableView.reloadData()
                } else {
                    self.tableView.beginUpdates()
                    self.tableView.deleteRows(at: removedIndexPaths, with: .automatic)
                    self.tableView.insertRows(at: addedIndexPaths, with: .automatic)
                    self.tableView.endUpdates()
                }
                self.updateTableHeader()
                self.updateTableFooter()
            }
        }
        
        viewModel.didSetErrorMessage = { message in
            self.updateTableHeader()
        }
        
        viewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                log.debug("isLoading: \(isLoading)")
                if isLoading {
                    if self.viewModel.currentPage == 0 {
                        self.refreshControl.beginRefreshing()
                    } else {
                        self.loadMoreSpinner.startAnimating()
                    }
                } else {
                    self.refreshControl.endRefreshing()
                    self.loadMoreSpinner.stopAnimating()
                }
                self.updateTableHeader()
                self.updateTableFooter()
            }
        }
        viewModel.fetchListItems(forceReload: false)
        updateTableFooter()
        refreshControl.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)
    }
  
    func updateTableHeader() {
        let visibleHeaderFrame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: tableHeaderHeight)
        if let msg = viewModel.errorMessage {
            self.tableHeaderView.frame = visibleHeaderFrame
            self.tableHeaderLabel.text = msg
            self.tableHeaderLabel.textColor = UIColor.error
        } else if viewModel.listItems.count == 0 && !viewModel.isLoading {
            self.tableHeaderView.frame = visibleHeaderFrame
            self.tableHeaderLabel.text = Strings.NoArtistsToShowMessage
            self.tableHeaderLabel.textColor = UIColor.lightGray
        } else {
            self.tableHeaderView.frame.size.height = 0
        }
    }
    
    func updateTableFooter() {
        loadMoreButton.isHidden = !viewModel.showOptionToLoadMore
    }

    @objc private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.fetchListItems(forceReload: true)
    }
    @objc func pressedLoadMoreArtists(_: UIButton) {
        viewModel.fetchListItems(forceReload: false)
    }
    func updateContentHeight() {
        let height = tableHeaderView.bounds.height
            + (CGFloat(viewModel.listItems.count) * lastCellHeight)
            + tableFooterView.bounds.height
            + (self.listTitle != nil ? sectionHeaderHeight : 0)
        self.tabContentDelegate?.didUpdateContentSize(controller: self, height: height)
    }
    
    func removeArtistFromView(_ artist: Artist) {
         guard let artistIndex = viewModel.listItems.firstIndex(where: { $0.id == artist.id }) else {
            return
        }
        self.tableView.beginUpdates()
        viewModel.removeListItem(atIndex: artistIndex)
        self.tableView.deleteRows(at: [IndexPath(row: artistIndex, section: 0)], with: .automatic)
        self.tableView.endUpdates()
    }
}

extension ArtistListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.listItems.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistCell", for: indexPath) as? ArtistCell else {
            fatalError("Couldnt' dequeue artist cell") }
        let artist = viewModel.listItems[indexPath.row]
//        if let firstFile = artist.ArtistImages?.first {
//            if let thumb = firstFile.thumbnail {
//                let imageJob = appContext.fileCache.getJobForFile(thumb)
//                cell.downloadJob = imageJob
//            } else {
//                let imageJob = appContext.fileCache.getJobForFile(firstFile)
//                cell.downloadJob = imageJob
//            }
//        }
        // cell.appContext = appContext
        cell.artist = artist
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = self.listTitle {
            return TableSectionHeaderView(height: sectionHeaderHeight, title: title)
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.isLoading {
            return 0
        }
        if self.listTitle != nil {
            return sectionHeaderHeight
        }
        return 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let artist = viewModel.listItems[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as? ArtistCell
        let thumbImage = cell?.imageView?.image
        let vc = ArtistProfileViewController(artist: artist, appContext: appContext)
        // vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let canEdit = artistListDelegate?.canEditArtists {
            return canEdit
        }
        return false
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.artistListDelegate?.didDeleteArtist(viewModel.listItems[indexPath.row], atIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == viewModel.listItems.count - 1 {
            self.lastCellHeight = cell.bounds.height
            self.updateContentHeight()
        }
    }
}

extension ArtistListViewController: ArtistProfileDelegate {
    func artistDetail(_ controller: ArtistProfileViewController, didUpdateArtist artist: Artist) {
        DispatchQueue.main.async {
            guard let artistIndex = self.viewModel.listItems.firstIndex(where: { $0.id == artist.id }) else { return }
            self.tableView.reloadRows(at: [IndexPath(row: artistIndex, section: 0)], with: .automatic)
        }
    }
    
    func artistDetail(_ controller: ArtistProfileViewController, didDeleteArtist artist: Artist) {
        self.removeArtistFromView(artist)
    }
    
    func artistDetail(_ controller: ArtistProfileViewController, didBlockUser user: User) {
        viewModel.fetchListItems(forceReload: true)
    }
}
extension ArtistListViewController: ArtistCellDelegate {
    func artistCell(_ cell: ArtistCell, didBlockUser user: User) {
        viewModel.fetchListItems(forceReload: true)
    }
    
    func artistCell(_ cell: ArtistCell, didSelectUser user: User) {
        let vc = ProfileViewController(user: user, appContext: appContext)
        navigationController?.pushViewController(vc, animated: true)
    }
    func artistCell(_ cell: ArtistCell, didUpdateArtist artist: Artist, atIndexPath indexPath: IndexPath) {
        viewModel.updateListItem(atIndex: indexPath.row, updatedItem: artist)
    }
    func artistCell(_ cell: ArtistCell, didDeleteArtist artist: Artist, atIndexPath indexPath: IndexPath) {
        self.removeArtistFromView(artist)
    }
}
extension ArtistListViewController: TabContentViewController {
    var contentScrollView: UIScrollView? {
        return self.tableView
    }
}

protocol ArtistCellDelegate: NSObject {
    
}
class ArtistCell: UITableViewCell {
    var artist: Artist? {
        didSet {
            
        }
    }
    var indexPath: IndexPath?
    weak var delegate: ArtistCellDelegate?
    static let reuseID = "ArtistCell"
}
