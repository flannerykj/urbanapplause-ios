//
//  SearchArtistsViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-15.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import Shared

protocol ArtistSelectionDelegate: class {
    func artistSelectionController(_ controller: ArtistSelectionViewController,
                                   didSelectArtist artist: Artist?)
}
class ArtistSelectionViewController: UITableViewController {
    var appContext: AppContext
    var selectedArtist: Artist?
    
    var isLoading = false {
        didSet {
            // TODO
        }
    }
    var artists = [Artist]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    var errorMessage: String? = nil {
        didSet {
            // TODO
        }
    }
    
    weak var delegate: ArtistSelectionDelegate?
    var multiSelectionEnabled: Bool = false
    
    lazy var searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 100, height: 60))
    
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
        searchBar.placeholder = Strings.ArtistSearchPlaceholder
        let addButton = UIBarButtonItem(title: Strings.CreateNewButtonTitle,
                                        style: .plain,
                                        target: self,
                                        action: #selector(createArtist(_:)))
        navigationItem.rightBarButtonItem = addButton
        searchBar.becomeFirstResponder()
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedArtist = artists[indexPath.row]
        delegate?.artistSelectionController(self, didSelectArtist: self.selectedArtist)
    }
}

extension ArtistSelectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.getArtists(query: searchText)
    }
}
extension ArtistSelectionViewController: CreateArtistDelegate {
    func createArtistController(_ controller: CreateArtistViewController, didCreateArtist artist: Artist) {
        self.selectedArtist = artist
        delegate?.artistSelectionController(self, didSelectArtist: artist)
        if navigationController?.viewControllers.first == controller {
            navigationController?.popViewController(animated: true)
        }
    }
}
