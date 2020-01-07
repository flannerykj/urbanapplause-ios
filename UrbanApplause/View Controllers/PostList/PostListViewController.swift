//
//  HomeViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//
import UIKit
import CoreLocation
import UrbanApplauseShared

protocol PostListControllerDelegate: class {
    var canEditPosts: Bool { get }
    func didDeletePost(_ post: Post, atIndexPath indexPath: IndexPath)
}

class PostListViewController: UIViewController {
    var contentHeight: CGFloat {
        return self.tableView.contentSize.height
    }
    weak var tabContentDelegate: TabContentDelegate?
    let tableHeaderHeight: CGFloat = 80
    let tableFooterHeight: CGFloat = 80
    let sectionHeaderHeight: CGFloat = 60
    
    var query: String?
    var mainCoordinator: MainCoordinator
    var viewModel: PostListViewModel
    var backgroundColor = UIColor.systemGray6
    var tableContentHeight: CGFloat = 0
    weak var postListDelegate: PostListControllerDelegate?
    let LEFT_EDITING_MARGIN: CGFloat = 12
    var listTitle: String?
    var requestOnLoad: Bool
    var lastCellHeight: CGFloat = 0
    
    init(listTitle: String? = nil,
         viewModel: PostListViewModel,
         requestOnLoad: Bool = true,
         mainCoordinator: MainCoordinator) {
        
        self.mainCoordinator = mainCoordinator
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
                                       title: "Load more posts",
                                       target: self,
                                       action: #selector(pressedLoadMorePosts(_:)))
    
    let loadMoreSpinner = ActivityIndicator()

    lazy var tableFooterView: UIView = {
        loadMoreButton.setTitle("Load more posts", for: .normal)
        loadMoreButton.addTarget(self, action: #selector(pressedLoadMorePosts(_:)), for: .touchUpInside)
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
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
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
        
        viewModel.didUpdateData = { addedIndexPaths, removedIndexPaths, shouldReload in
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
        self.refreshControl.beginRefreshing()
        viewModel.getPosts(forceReload: false)
        updateTableFooter()
        refreshControl.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)
    }
  
    func updateTableHeader() {
        let visibleHeaderFrame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: tableHeaderHeight)
        if let msg = viewModel.errorMessage {
            self.tableHeaderView.frame = visibleHeaderFrame
            self.tableHeaderLabel.text = msg
            self.tableHeaderLabel.textColor = UIColor.error
        } else if viewModel.posts.count == 0 && !viewModel.isLoading {
            self.tableHeaderView.frame = visibleHeaderFrame
            self.tableHeaderLabel.text = "No posts to show"
            self.tableHeaderLabel.textColor = UIColor.lightGray
        } else {
            self.tableHeaderView.frame.size.height = 0
        }
    }
    
    func updateTableFooter() {
        loadMoreButton.isHidden = !viewModel.showOptionToLoadMore
    }

    @objc private func refreshControlTriggered(_ sender: UIRefreshControl) {
        viewModel.getPosts(forceReload: true)
    }
    @objc func pressedLoadMorePosts(_: UIButton) {
        viewModel.getPosts(forceReload: false)
    }
    func updateContentHeight() {
        let height = tableHeaderView.bounds.height
            + (CGFloat(viewModel.posts.count) * lastCellHeight)
            + tableFooterView.bounds.height
            + (self.listTitle != nil ? sectionHeaderHeight : 0)
        self.tabContentDelegate?.didUpdateContentSize(controller: self, height: height)
    }
    
    func removePostFromView(_ post: Post) {
         guard let postIndex = viewModel.posts.firstIndex(where: { $0.id == post.id }) else {
            return
        }
        self.tableView.beginUpdates()
        viewModel.removePost(atIndex: postIndex)
        self.tableView.deleteRows(at: [IndexPath(row: postIndex, section: 0)], with: .automatic)
        self.tableView.endUpdates()
    }
}

extension PostListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            fatalError("Couldnt' dequeue post cell") }
        let post = viewModel.posts[indexPath.row]
        if let firstFile = post.PostImages?.first {
            if let thumb = firstFile.thumbnail {
                let imageJob = mainCoordinator.fileCache.getJobForFile(thumb)
                cell.downloadJob = imageJob
            } else {
                let imageJob = mainCoordinator.fileCache.getJobForFile(firstFile)
                cell.downloadJob = imageJob
            }
        }
        cell.mainCoordinator = mainCoordinator
        cell.post = post
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let title = self.listTitle {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: sectionHeaderHeight))
            view.layoutMargins = StyleConstants.defaultMarginInsets
            view.backgroundColor = UIColor.backgroundMain
            let label = UILabel(type: .h8, text: title)
            view.addSubview(label)
            view.layoutMargins = StyleConstants.defaultPaddingInsets
            label.fillWithinMargins(view: view)
            return view
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
        let post = viewModel.posts[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as? PostCell
        let thumbImage = cell?.imageView?.image
        let vc = PostDetailViewController(postId: post.id,
                                          post: post,
                                          thumbImage: thumbImage,
                                          mainCoordinator: mainCoordinator)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let canEdit = postListDelegate?.canEditPosts {
            return canEdit
        }
        return false
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.postListDelegate?.didDeletePost(viewModel.posts[indexPath.row], atIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row == viewModel.posts.count - 1 {
            self.lastCellHeight = cell.bounds.height
            self.updateContentHeight()
        }
    }
}

extension PostListViewController: PostDetailDelegate {
    func postDetail(_ controller: PostDetailViewController, didUpdatePost post: Post) {
        DispatchQueue.main.async {
            guard let postIndex = self.viewModel.posts.firstIndex(where: { $0.id == post.id }) else { return }
            self.tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .automatic)
        }
    }
    
    func postDetail(_ controller: PostDetailViewController, didDeletePost post: Post) {
        self.removePostFromView(post)
    }
    
    func postDetail(_ controller: PostDetailViewController, didBlockUser user: User) {
        viewModel.getPosts(forceReload: true)
    }
}
extension PostListViewController: PostCellDelegate {
    func postCell(_ cell: PostCell, didBlockUser user: User) {
        viewModel.getPosts(forceReload: true)
    }
    
    func postCell(_ cell: PostCell, didSelectUser user: User) {
        let vc = ProfileViewController(user: user, mainCoordinator: mainCoordinator)
        navigationController?.pushViewController(vc, animated: true)
    }
    func postCell(_ cell: PostCell, didUpdatePost post: Post, atIndexPath indexPath: IndexPath) {
        viewModel.updatePost(atIndex: indexPath.row, updatedPost: post)
    }
    func postCell(_ cell: PostCell, didDeletePost post: Post, atIndexPath indexPath: IndexPath) {
        self.removePostFromView(post)
    }
}
extension PostListViewController: TabContentViewController {
    var contentScrollView: UIScrollView? {
        return self.tableView
    }
}
