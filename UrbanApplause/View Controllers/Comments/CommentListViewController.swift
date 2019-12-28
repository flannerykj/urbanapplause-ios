//
//  CommentListViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol CommentListDelegate: class {
    func commentList(didUpdateComments comments: [Comment])
}

class CommentListViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var viewModel: CommentListViewModel
    weak var delegate: CommentListDelegate?
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                self.downloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    var post: Post? {
        didSet {
            if let firstFile = post?.PostImages?.first {
               if let thumb = firstFile.thumbnail {
                   let imageJob = mainCoordinator.fileCache.getJobForFile(thumb)
                   self.downloadJob = imageJob
               } else {
                   let imageJob = mainCoordinator.fileCache.getJobForFile(firstFile)
                   self.downloadJob = imageJob
               }
           }
        }
    }
    var downloadJob: FileDownloadJob? {
        didSet {
            guard let job = downloadJob else {
                return
            }
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    self.tableHeaderView.image = UIImage(data: data)
                }
            })
        }
    }
    
    init(viewModel: CommentListViewModel,
         mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var refreshControl = UIRefreshControl()
    
    lazy var saveCommentButton = UAButton(type: .link,
                                          title: "Submit",
                                          target: self,
                                          action: #selector(createComment(_:)))
    
    let newCommentTextArea = UATextArea(placeholder: "Add a comment", value: nil)

    lazy var tableHeaderView: UIImageView = {
        let view = UIImageView(frame: CGRect(x: 0, y: 0, width: 1, height: 200))
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    lazy var tableFooterView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 150))
        view.backgroundColor = .systemGray5
        view.accessibilityIdentifier = "commentList-tableHeaderView"
        saveCommentButton.titleLabel?.textAlignment = .right
        view.addSubview(newCommentTextArea)
        view.addSubview(saveCommentButton)
        view.layoutMargins = StyleConstants.defaultMarginInsets
        newCommentTextArea.backgroundColor = UIColor.systemGray5
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .clear
        
        view.addSubview(dividerView)
        NSLayoutConstraint.activate([
            dividerView.topAnchor.constraint(equalTo: view.topAnchor),
            dividerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            dividerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            newCommentTextArea.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 24),
            newCommentTextArea.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            newCommentTextArea.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            
            saveCommentButton.topAnchor.constraint(equalTo: newCommentTextArea.bottomAnchor),
            saveCommentButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
            saveCommentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }()
    
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = tableFooterView
        tableView.backgroundColor = UIColor.backgroundMain
        tableView.separatorColor = .systemGray
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.fill(view: self.view)
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = closeButton
        tableView.scrollViewAvoidKeyboard()
        view.backgroundColor = UIColor.backgroundMain
        viewModel.getComments()
        newCommentTextArea.autocorrectionType = .no
        newCommentTextArea.autocapitalizationType = .sentences
        setModelCallbacks()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    func setModelCallbacks() {
        viewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self.refreshControl.beginRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                }
            }
        }
        viewModel.didSetSubmitting = { isSubmitting in
            DispatchQueue.main.async {
                if isSubmitting {
                    self.saveCommentButton.showLoading()
                } else {
                    self.saveCommentButton.hideLoading()
                }
            }
        }
        viewModel.didSetErrorMessage = { message in
            guard message != nil else { return }
            DispatchQueue.main.async {
                self.showAlert(message: message)
            }
        }
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
            }
        }
        
        viewModel.didDeleteComment = { comment in
            DispatchQueue.main.async {
                self.delegate?.commentList(didUpdateComments: self.viewModel.comments)
                self.showAlert(message: "Your comment has been deleted.")
            }
        }
        viewModel.didCreateComment = { _ in
            DispatchQueue.main.async {
                self.newCommentTextArea.clearText()
                self.newCommentTextArea.resignFirstResponder()
                self.delegate?.commentList(didUpdateComments: self.viewModel.comments)
            }
        }
        
        viewModel.didBlockUser = { user in
            DispatchQueue.main.async {
                self.viewModel.getComments()
                self.showAlert(message: "\(user.username ?? "this user") has been blocked")
            }
        }
    }
    
    func flagComment(_ comment: Comment) {
        let vc = ReportAnIssueViewController(store: mainCoordinator.store) { reportController, reason in
            reportController.isSubmitting = true
            let endpoint = PrivateRouter.createCommentFlag(commentId: comment.id, reason: reason)
            _ = self.mainCoordinator.networkService.request(endpoint) { (result: UAResult<CommentFlagContainer>) in
                DispatchQueue.main.async {
                    reportController.self.isSubmitting = false
                    switch result {
                    case .success:
                        reportController.didSubmit = true
                    case .failure(let error):
                        reportController.handleError(error: error)
                    }
                }
            }
        }
        present(UINavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func blockUser(_ user: User) {
        let username = user.username ?? "this user"
        let alertController = UIAlertController(title: "Block \(username)?",
            message: "You will no longer be show posts or comments from this user.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        let blockAction = UIAlertAction(title: "Block", style: .destructive, handler: { _ in
            self.viewModel.blockUser(user)
        })
        alertController.addAction(cancelAction)
        alertController.addAction(blockAction)
        self.presentAlertInCenter(alertController)
        present(alertController, animated: true, completion: nil)
    }

    @objc func refreshData(_: Any) {
        viewModel.getComments()
    }
    
    @objc func cancel(_: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func createComment(_: Any) {
        viewModel.submitComment(contents: newCommentTextArea.text)
    }
}

extension CommentListViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.comments.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseIdentifier,
                                                       for: indexPath) as? CommentCell else { fatalError() }
        let comment = viewModel.comments[indexPath.row]
        cell.comment = comment
        cell.delegate = self
        cell.indexPath = indexPath
        cell.contentView.backgroundColor = UIColor.backgroundMain
        return cell
    }
}

extension CommentListViewController: CommentCellDelegate {
    func commentCell(_ sender: UIButton, showMoreOptionsForComment comment: Comment, atIndexPath indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let user = self.mainCoordinator.store.user.data, let post = self.post, post.UserId == user.id {
            let deleteAction = UIAlertAction(title: "Delete comment", style: .default, handler: { _ in
                self.confirmDeleteComment(comment, atIndexPath: indexPath)
            })
            alertController.addAction(deleteAction)
        } else {
             let reportPostAction = UIAlertAction(title: "Report this comment",
                                                  style: .default, handler: { _ in
                                                self.flagComment(comment)
                                                    
             })
            let blockAction = UIAlertAction(title: "Block \(comment.User?.username ?? "this user")",
                style: .default,
                handler: { _ in
                    
                guard let user = comment.User else { return }
                self.blockUser(user)
            })
            alertController.addAction(reportPostAction)
            alertController.addAction(blockAction)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.popoverPresentationController?.sourceView = sender
        alertController.popoverPresentationController?.sourceRect = sender.bounds
        alertController.addAction(cancelAction)
        self.presentAlertInCenter(alertController)
    }
    
    func commentCell(didSelectUser user: User) {
        // let vc = ProfileViewController(user: user, mainCoordinator: mainCoordinator)
        // navigationController?.pushViewController(vc, animated: true)
    }
    func confirmDeleteComment(_ comment: Comment, atIndexPath indexPath: IndexPath) {
        let alertController = UIAlertController(title: "Are you sure you want to delete this comment?",
                                                message: "This cannot be undone.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                   alertController.dismiss(animated: true, completion: nil)
               })
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.viewModel.deleteComment(comment, at: indexPath)
        })
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        presentAlertInCenter(alertController)
    }
}
