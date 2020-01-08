//
//  SearchArtistsViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-15.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol ArtistSelectionDelegate: class {
    func artistSelectionController(finishWithArtist artist: Artist?)
}
class ArtistSelectionViewController: UITableViewController {
    var appContext: AppContext
    var selectedArtist: Artist?
    
    var isLoading = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    var artists = [Artist]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    var errorMessage: String? = nil {
        didSet {
            
        }
    }
    
    weak var delegate: ArtistSelectionDelegate?
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.hidesWhenStopped = true
        let addButton = UIBarButtonItem(title: "Create new",
                                        style: .plain,
                                        target: self,
                                        action: #selector(createArtist(_:)))
        navigationItem.rightBarButtonItem = addButton
    }
    
    @objc func createArtist(_: Any) {
        let vc = CreateArtistViewController(appContext: self.appContext)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func getArtists(query: String) {
        let endpoint = PrivateRouter.getArtists(query: ["search": query])
        _ = appContext.networkService.request(endpoint) { [weak self] (result: UAResult<ArtistsContainer>) in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    log.error(error)
                    self?.isLoading = false
                    self?.errorMessage = error.userMessage
                case .success(let artistsContainer):
                    self?.isLoading = false
                    self?.artists = artistsContainer.artists
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.artistSelectionController(finishWithArtist: self.selectedArtist)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let selectedItem = artists[indexPath.row]
        cell.textLabel?.text = "\(selectedItem.signing_name ?? "")"
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
        self.selectedArtist = artists[indexPath.row]
        navigationController?.popViewController(animated: true)
    }
}

extension ArtistSelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.getArtists(query: searchText)
    }
}
extension ArtistSelectionViewController: CreateArtistDelegate {
    func didCreateArtist(_ artist: Artist) {
        self.selectedArtist = artist
        log.debug("created artist: \(artist)")
        navigationController?.popViewController(animated: true)
    }
}
