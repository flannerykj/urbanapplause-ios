//
//  CollectionsViewControllerTableViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit

protocol CollectionListDelegate: class {
    func collectionList(_ controller: CollectionListViewController,
                        didSelectCollection collection: Collection,
                        at indexPath: IndexPath)
    
    func collectionList(_ controller: CollectionListViewController,
                        accessoryViewForCollection collection: Collection,
                        at indexPath: IndexPath) -> UIView?
}

class CollectionListViewController: UIViewController {
    var mainCoordinator: MainCoordinator
    var viewModel: CollectionListViewModel
    weak var delegate: CollectionListDelegate?
    let tableHeaderHeight: CGFloat = 80
    
    init(viewModel: CollectionListViewModel,
         mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var refreshControl = UIRefreshControl()
    
    let tableHeaderLabel = UILabel(type: .body)
    
    lazy var tableHeaderView: UIView = {
       tableHeaderLabel.textAlignment = .center
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: tableHeaderHeight))
        view.addSubview(tableHeaderLabel)
        tableHeaderLabel.fill(view: view)
        return view
    }()
    
    lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CollectionCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.backgroundMain
        tableView.separatorColor = UIColor.systemGray
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.fill(view: self.view)
        
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)

        // nav setup
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancel(_:)))
        navigationItem.rightBarButtonItem = doneButton
    
        // view model callbacks
        viewModel.didUpdateData = { _ in
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.updateTableHeader()
            }
        }
        viewModel.didSetErrorMessage = { message in
            DispatchQueue.main.async {
                self.updateTableHeader()
            }
        }
        viewModel.didSetLoading = { isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self.refreshControl.beginRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                }
            }
        }
        
        // fetch data
        viewModel.getCollections()
    }
    
    func updateTableHeader() {
        let visibleHeaderFrame = CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: tableHeaderHeight)
        if let msg = viewModel.errorMessage {
            self.tableHeaderView.frame = visibleHeaderFrame
            self.tableHeaderLabel.text = msg
            self.tableHeaderLabel.textColor = UIColor.error
        } else if viewModel.collections.count == 0 && !viewModel.isLoading {
            self.tableHeaderView.frame = visibleHeaderFrame
            self.tableHeaderLabel.text = "Create a gallery to start saving posts."
            self.tableHeaderLabel.textColor = UIColor.lightGray
        } else {
            self.tableHeaderView.frame.size.height = 0
        }
    }
    @objc func refreshData(_: Any) {
        viewModel.getCollections()
    }
    
    @objc func cancel(_: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func createCollection(_: UIButton) {
        let vc = NewCollectionViewController(mainCoordinator: mainCoordinator)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension CollectionListViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.collections.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath)
        let collection = viewModel.collections[indexPath.row]
        cell.textLabel?.text = collection.title
        /* if let postCount = collection.Posts?.count {
            cell.detailTextLabel?.text = String.pluralize(postCount, unit: "post")
        } */
        cell.backgroundColor = UIColor.backgroundMain
        cell.accessoryView = delegate?.collectionList(self, accessoryViewForCollection: collection, at: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.collectionList(self, didSelectCollection: viewModel.collections[indexPath.row], at: indexPath)
    }
}

extension CollectionListViewController: NewCollectionViewControllerDelegate {
    func didCreateCollection(collection: Collection) {
        self.tableView.beginUpdates()
        self.viewModel.collections = [collection] + self.viewModel.collections
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        self.tableView.endUpdates()
    }
}
