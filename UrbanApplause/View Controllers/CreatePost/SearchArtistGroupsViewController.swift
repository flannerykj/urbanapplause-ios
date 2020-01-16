//
//  SearchArtistGroupsViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-16.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

protocol ArtistGroupSelectionDelegate: class {
    func artistGroupSelectionController(_ controller: ArtistGroupSelectionViewController,
                                   didSelectArtistGroup artistGroup: ArtistGroup?)
}
class ArtistGroupSelectionViewController: UITableViewController {
    var appContext: AppContext
    var selectedArtistGroup: ArtistGroup?
    
    var isLoading = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    var artistGroups = [ArtistGroup]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    var errorMessage: String? = nil {
        didSet {
            
        }
    }
    
    weak var delegate: ArtistGroupSelectionDelegate?
    var multiSelectionEnabled: Bool = false
    
    lazy var searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
    lazy var activityIndicator = ActivityIndicator()
    
    init(appContext: AppContext) {
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
        tableView.tableHeaderView = searchBar
        searchBar.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.tableFooterView = UIView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.placeholder = Strings.ArtistGroupSearchPlaceholder
        activityIndicator.hidesWhenStopped = true
        let addButton = UIBarButtonItem(title: Strings.CreateNewButtonTitle,
                                        style: .plain,
                                        target: self,
                                        action: #selector(createArtistGroup(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func createArtistGroup(_: Any) {
        let vc = CreateArtistGroupViewController(appContext: self.appContext)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func getArtistGroups(query: String) {
        let endpoint = PrivateRouter.getArtistGroups(query: ["search": query])
        _ = appContext.networkService.request(endpoint) { [weak self] (result: UAResult<ArtistGroupsContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.isLoading = false
                    self?.errorMessage = error.userMessage
                case .success(let artistGroupsContainer):
                    self?.isLoading = false
                    self?.artistGroups = artistGroupsContainer.artist_groups
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artistGroups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let selectedItem = artistGroups[indexPath.row]
        cell.textLabel?.text = "\(selectedItem.name ?? "")"
        cell.detailTextLabel?.text = ""
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
            view.addSubview(activityIndicator)
            NSLayoutConstraint.activate([
                activityIndicator.topAnchor.constraint(equalTo: view.topAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isLoading {
            return 50
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedArtistGroup = artistGroups[indexPath.row]
        delegate?.artistGroupSelectionController(self, didSelectArtistGroup: self.selectedArtistGroup)
    }
}

extension ArtistGroupSelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.getArtistGroups(query: searchText)
    }
}
extension ArtistGroupSelectionViewController: CreateArtistGroupDelegate {
    func createArtistGroupController(_ controller: CreateArtistGroupViewController, didCreateArtistGroup artistGroup: ArtistGroup) {
        self.selectedArtistGroup = artistGroup
        delegate?.artistGroupSelectionController(self, didSelectArtistGroup: artistGroup)
        if navigationController?.viewControllers.first == controller {
            navigationController?.popViewController(animated: true)
        }
    }
}
