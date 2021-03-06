//
//  CommentListViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared
import SnapKit

protocol CommentListDelegate: class {
    func commentList(didUpdateComments comments: [Comment])
}

class CommentListViewController: UIViewController {
    var appContext: AppContext
    var viewModel: CommentListViewModel
    weak var delegate: CommentListDelegate?

    var post: Post? {
        didSet {
            viewModel.setPost(post)
        }
    }

    init(viewModel: CommentListViewModel,
         appContext: AppContext) {
        self.appContext = appContext
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setModelCallbacks()
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


    lazy var tableFooterView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 150))
        view.backgroundColor = .systemGray5
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.backgroundColor = .clear
        view.addSubview(dividerView)
        view.layoutMargins = StyleConstants.defaultMarginInsets

       NSLayoutConstraint.activate([
           dividerView.topAnchor.constraint(equalTo: view.topAnchor),
           dividerView.leftAnchor.constraint(equalTo: view.leftAnchor),
           dividerView.rightAnchor.constraint(equalTo: view.rightAnchor),
           dividerView.heightAnchor.constraint(equalToConstant: 1)
        ])
        if appContext.authService.isAuthenticated {
            saveCommentButton.titleLabel?.textAlignment = .right
            view.addSubview(newCommentTextArea)
            view.addSubview(saveCommentButton)
            newCommentTextArea.backgroundColor = UIColor.systemGray5
           NSLayoutConstraint.activate([
                newCommentTextArea.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 24),
                newCommentTextArea.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
                newCommentTextArea.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
                
                saveCommentButton.topAnchor.constraint(equalTo: newCommentTextArea.bottomAnchor),
                saveCommentButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor),
                saveCommentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        } else {
            view.frame.size.height = 80
            let textView = UATextView()
            textView.isSelectable = true // prevents delay in responding to tap on linked text
            textView.delegate = self
            let prepend = "You must "
            let linkText = "log in"
            let appendText = " to comment."
            let text = NSMutableAttributedString(attributedString: NSAttributedString(string: prepend + linkText + appendText))
            var style = NSMutableParagraphStyle()
            style.lineSpacing = 8
            text.addAttributes([
                .font: TypographyStyle.body.font,
                .foregroundColor: UIColor.customTextColor,
                .paragraphStyle: style,
                .backgroundColor: UIColor.clear
            ], range: NSRange(location: 0, length: text.length))
            text.addAttributes([.link: ""], range: NSRange(location: prepend.count, length: linkText.count))
            textView.linkTextAttributes = [
                .foregroundColor: UIColor.systemBlue
            ]
            textView.attributedText = text
            view.addSubview(textView)
            textView.snp.makeConstraints {
                $0.edges.equalTo(view)
            }
        }
        return view
    }()
    
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = tableFooterView
        tableView.backgroundColor = UIColor.systemBackground
        tableView.separatorColor = .systemGray
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.edges.equalTo(view)
        }
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(cancel(_:)))
        navigationItem.leftBarButtonItem = closeButton
        tableView.scrollViewAvoidKeyboard()
        view.backgroundColor = UIColor.systemBackground
        viewModel.getComments()
        newCommentTextArea.autocorrectionType = .no
        newCommentTextArea.autocapitalizationType = .sentences
        
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
                log.debug("added: \(addedIndexPaths.count)")
                log.debug("removed: \(removedIndexPaths.count)")
                log.debug("should reload: \(shouldReload)")
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
        let vc = ReportAnIssueViewController(store: appContext.store) { reportController, reason in
            reportController.isSubmitting = true
            let endpoint = PrivateRouter.createCommentFlag(commentId: comment.id, reason: reason)
            _ = self.appContext.networkService.request(endpoint) { (result: UAResult<CommentFlagContainer>) in
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
        /*if indexPath.section == 0 {
            let cell = UITableViewCell()
            cell.textLabel?.text = "No comments have been added."
            cell.textLabel?.style(as: .placeholder)
            return cell
        } */
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseIdentifier,
                                                       for: indexPath) as? CommentCell else { fatalError() }
        let comment = viewModel.comments[indexPath.row]
        cell.comment = comment
        cell.delegate = self
        cell.indexPath = indexPath
        cell.contentView.backgroundColor = UIColor.systemBackground
        return cell
    }
}

extension CommentListViewController: CommentCellDelegate {
    func commentCell(_ sender: UIButton, showMoreOptionsForComment comment: Comment, atIndexPath indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let user = self.appContext.store.user.data, let post = self.post, post.UserId == user.id {
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
        // let vc = ProfileViewController(user: user, appContext: appContext)
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
extension CommentListViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.showAuth(isNewUser: false, appContext: appContext)
        return false
    }
}
