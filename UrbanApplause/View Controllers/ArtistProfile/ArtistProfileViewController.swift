//
//  ArtistProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol ArtistProfileDelegate: AnyObject {
    
}

class ArtistProfileViewController: UIViewController {
    
    
 var mainCoordinator: MainCoordinator
    var viewModel: ArtistProfileViewModel
    weak var delegate: ArtistProfileDelegate?

    var artist: Artist? {
        didSet {
            viewModel.setArtist(artist)
        }
    }

    init(viewModel: ArtistProfileViewModel,
         mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var refreshControl = UIRefreshControl()

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

        return view
    }()
    
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseIdentifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
        viewModel.fetchArtist()
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
        viewModel.didSetErrorMessage = { message in
            guard message != nil else { return }
            DispatchQueue.main.async {
                self.showAlert(message: message)
            }
        }
        viewModel.didUpdateData = { artist in
            DispatchQueue.main.async {
                self.tableView.reloadData()
                // Todo - update artist proile info
            }
        }
    }
    

    @objc func refreshData(_: Any) {
        viewModel.fetchArtist()
    }
    
    @objc func cancel(_: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ArtistProfileViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            // meta - messages
            return 0
        }
        return  0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell()
            cell.textLabel?.text = "This artist hasn't been tagged in any posts."
            cell.textLabel?.style(as: .placeholder)
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier,
                                                       for: indexPath) as? PostCell else { fatalError() }
        guard let post = viewModel.artist?.Posts?[indexPath.row] else { fatalError() }
        cell.post = post
        cell.delegate = self
        cell.indexPath = indexPath
        cell.contentView.backgroundColor = UIColor.backgroundMain
        return cell
    }
}

extension ArtistProfileViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        self.showAuth(isNewUser: false, mainCoordinator: mainCoordinator)
        return false
    }
}
extension ArtistProfileViewController: PostCellDelegate {
    func postCell(_ cell: PostCell, didUpdatePost post: Post, atIndexPath indexPath: IndexPath) {
        
    }
    
    func postCell(_ cell: PostCell, didSelectUser user: User) {
        
    }
    
    func postCell(_ cell: PostCell, didBlockUser user: User) {
        
    }
    
    func postCell(_ cell: PostCell, didDeletePost post: Post, atIndexPath indexPath: IndexPath) {
        
    }
    
    
}
