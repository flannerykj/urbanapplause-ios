//
//  CollectionsViewControllerTableViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-04-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit
import Combine
import Shared
import SnapKit

protocol GalleryListDelegate: class {
    func galleryList(_ controller: GalleriesListViewController,
                     didSelectCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath)
    
    func galleryList(_ controller: GalleriesListViewController,
                     accessoryViewForCellModel cellModel: GalleryCellViewModel,
                     at indexPath: IndexPath) -> UIView?
}


protocol GalleriesListViewControllable: UIViewController {
    
}

class GalleriesListViewController: UIViewController, GalleriesListViewControllable {

    var subscriptions = Set<AnyCancellable>()
    @Published var animate: Bool = false
    var appContext: AppContext
    private var viewModel: GalleryListViewModel
    weak var delegate: GalleryListDelegate?
    let tableHeaderHeight: CGFloat = 80
    lazy var dataSource = self.makeDataSource()
    
    init(viewModel: GalleryListViewModel,
         appContext: AppContext) {
        self.appContext = appContext
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var refreshControl = UIRefreshControl()
    
    let errorMessageLabel = UILabel(type: .body, color: .systemRed)
    let noResultsMessageLabel = UILabel(type: .body)
    
    private lazy var tableView: UATableView = {
       let tableView = UATableView()
        tableView.refreshControl = refreshControl
        tableView.register(GalleryCell.self, forCellReuseIdentifier: GalleryCell.ReuseID)
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = UIColor.systemBackground
        return tableView
    }()
    
    func makeDataSource() -> GalleriesTableSource {
        return GalleriesTableSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, cellModel in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: GalleryCell.ReuseID,
                    for: indexPath
                )
                cell.textLabel?.text = cellModel.gallery.title
                cell.detailTextLabel?.text = String.pluralize(cellModel.posts.count, unit: "post")
                cell.backgroundColor = UIColor.systemBackground
                cell.accessoryView = self.delegate?.galleryList(self, accessoryViewForCellModel: cellModel, at: indexPath)
                    // cell.imageView?.image = cellModel.gallery.icon
                return cell
            },
            isEditable: viewModel.isEditable
        )
    }
    
    func reloadGalleryCells(_ cellModels: [GalleryCellViewModel], animate: Bool) {
        var snapshot = dataSource.snapshot()
        snapshot.reloadItems(cellModels)
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
        
        if needsRefreshOnViewAppear {
            viewModel.refreshData()
            needsRefreshOnViewAppear = false
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        view.backgroundColor = .systemBackground
        // nav setup
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancel(_:)))
        navigationItem.rightBarButtonItem = doneButton

        // fetch data
        refreshControl.beginRefreshing()
        tableView.dataSource = self.dataSource

        setupSubscriptions()
    }
    
    // MARK: - Private

    private func setupSubviews() {
        errorMessageLabel.textAlignment = .center
        noResultsMessageLabel.textAlignment = .center
        tableView.backgroundColor = .clear
        
        view.addSubview(errorMessageLabel)
        errorMessageLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.view.safeAreaLayoutGuide).inset(8)
        }
        
        view.addSubview(noResultsMessageLabel)
        noResultsMessageLabel.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self.view.safeAreaLayoutGuide).inset(8)
        }
        
        view.addSubview(tableView)
        tableView.fill(view: self.view)
        
        tableView.addSubview(refreshControl)
    }
    
    private func setupSubscriptions() {
        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { isLoading in
                if isLoading {
                    self.refreshControl.beginRefreshing()
                } else {
                    self.refreshControl.endRefreshing()
                }
            })
            .store(in: &subscriptions)

        viewModel.snapshot
            .apply(to: dataSource, animate: $animate.eraseToAnyPublisher())
            .store(in: &subscriptions)
        
        viewModel.errorMessage
            .receive(on: DispatchQueue.main)
            .flatMap { Just($0) }
            .assign(to: \.text, on: errorMessageLabel)
            .store(in: &subscriptions)
        
        viewModel.noResultsMessage
            .receive(on: DispatchQueue.main)
            .flatMap { Just($0) }
            .assign(to: \.text, on: noResultsMessageLabel)
            .store(in: &subscriptions)
    }
    
    
    // MARK: - Selector Actions

    @objc func refreshData(_: Any) {
        viewModel.refreshData()
    }
    
    @objc func cancel(_: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func createCollection(_: UIButton) {
        let vc = CollectionFormViewController(existingCollection: nil, appContext: appContext)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private var needsRefreshOnViewAppear: Bool = false
    
    private func setNeedsRefresh() {
        self.needsRefreshOnViewAppear = true
    }
}

extension GalleriesListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cellModel = dataSource.itemIdentifier(for: indexPath) else { log.error("no gallery"); return }
        delegate?.galleryList(self, didSelectCellModel: cellModel, at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
 
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
        }
    }
}

extension GalleriesListViewController: NewCollectionViewControllerDelegate {
    func didUpdateCollection(collection: Collection) {
        viewModel.updateCollection(collection)
    }
    
    func didCreateCollection(collection: Collection) {
        viewModel.addCollection(collection)
    }
}


extension GalleriesListViewController: CollectionDetailControllerDelegate {
    func collectionDetail(didDeleteCollection collection: Collection) {
        setNeedsRefresh()
    }
    
    func collectionDetail(didDeletePostsFromCollection collection: Collection) {
        setNeedsRefresh()
    }
}
