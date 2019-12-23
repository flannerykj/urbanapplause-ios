//
//  CollectionsViewControllerTableViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Combine

protocol GalleryListDelegate: class {
    func galleryList(_ controller: GalleryListViewController,
                     didSelectGallery gallery: Gallery,
                     at indexPath: IndexPath)
    
    func galleryList(_ controller: GalleryListViewController,
                     accessoryViewForGallery gallery: Gallery,
                     at indexPath: IndexPath) -> UIView?
}

class GalleryListViewController: UIViewController {
    let uuid = UUID()
    var subscriptions = Set<AnyCancellable>()
    @Published var animate: Bool = false
    var mainCoordinator: MainCoordinator
    private var viewModel: GalleryListViewModel
    weak var delegate: GalleryListDelegate?
    let tableHeaderHeight: CGFloat = 80
    lazy var dataSource = self.makeDataSource()
    
    init(viewModel: GalleryListViewModel,
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
    
    private lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.refreshControl = refreshControl
        tableView.register(GalleryCell.self, forCellReuseIdentifier: GalleryCell.ReuseID)
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = tableHeaderView
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.backgroundMain
        tableView.separatorColor = UIColor.systemGray
        return tableView
    }()
    
    func makeDataSource() -> GalleriesTableSource {
        return GalleriesTableSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, gallery in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: GalleryCell.ReuseID,
                    for: indexPath
                )

                cell.textLabel?.text = gallery.title
                if let postCount = gallery.numberOfPosts {
                    cell.detailTextLabel?.text = String.pluralize(postCount, unit: "post")
                }
                cell.backgroundColor = UIColor.backgroundMain
                cell.accessoryView = self.delegate?.galleryList(self, accessoryViewForGallery: gallery, at: indexPath)
                cell.imageView?.image = gallery.icon
                return cell
            }
        )
    }
    
    func reloadGalleries(_ galleries: [Gallery], animate: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<GalleriesSection, Gallery>()
        snapshot.reloadItems(galleries)
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.fill(view: self.view)
        
        tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)

        // nav setup
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancel(_:)))
        navigationItem.rightBarButtonItem = doneButton

        // fetch data
        tableView.dataSource = self.dataSource

        viewModel.isLoading.sink(receiveValue: { isLoading in
            DispatchQueue.main.async {
                log.debug("is loading: \(isLoading)")
                if isLoading {
                    self.refreshControl.beginRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                }
            }
        }).store(in: &subscriptions)

        viewModel.errorMessage
            .sink(receiveValue: { errorMessage in
                let visibleHeaderFrame = CGRect(x: 0,
                                                y: 0,
                                                width: self.tableView.bounds.width,
                                                height: self.tableHeaderHeight)
                if let msg = errorMessage {
                    self.tableHeaderView.frame = visibleHeaderFrame
                    self.tableHeaderLabel.text = msg
                    self.tableHeaderLabel.textColor = UIColor.error
                } else {
                    self.tableHeaderView.frame.size.height = 0
                }
            }).store(in: &subscriptions)
        viewModel.getData()
        
        viewModel.snapshot
            .apply(to: dataSource, animate: $animate.eraseToAnyPublisher())
            .store(in: &subscriptions)
    }

    @objc func refreshData(_: Any) {
        viewModel.getData()
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

extension GalleryListViewController: UITableViewDelegate {
    // MARK: - Table view data source
    /* func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.tableData.value
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath)
        let collection = viewModel.collections[indexPath.row]
        cell.textLabel?.text = collection.title
        /* if let postCount = collection.Posts?.count {
            cell.detailTextLabel?.text = String.pluralize(postCount, unit: "post")
        } */
        cell.backgroundColor = UIColor.backgroundMain
        return cell
    } */
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("did select")
        guard let gallery = dataSource.itemIdentifier(for: indexPath) else { log.error("no gallery"); return }
        delegate?.galleryList(self, didSelectGallery: gallery, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        log.debug("GET hEIGHT")
        return 50
    }
    
    
}

extension GalleryListViewController: NewCollectionViewControllerDelegate {
    func didCreateCollection(collection: Collection) {
        viewModel.addCollection(collection)
    }
}


class GalleriesTableSource: UITableViewDiffableDataSource<GalleriesSection, Gallery> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.snapshot().sectionIdentifiers[section].title
    }
}
