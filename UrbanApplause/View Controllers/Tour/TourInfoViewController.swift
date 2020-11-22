//
//  TourInfoViewController.swift
//  UrbanApplause
//
//  Created by Flann on 2020-11-22.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Shared

enum TourInfoSection: Int, CaseIterable {
    case waypoints
}

class TourInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let collection: Collection
    private let appContext: AppContext

    init(collection: Collection, appContext: AppContext) {
        self.collection = collection
        self.appContext = appContext
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tableCell")
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemPink
        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TourInfoSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = TourInfoSection.allCases[section]
        switch section {
        case .waypoints:
            return collection.Posts?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = TourInfoSection.allCases[indexPath.section]
        switch section {
        case .waypoints:
            let post = (collection.Posts ?? [])[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
            cell.textLabel?.text = "post.title"
//            cell.detailTextLabel?.text = post.sub
            return cell
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        let section = TourInfoSection.allCases[section]
//        switch section {
//        case .waypoints:
//            return "Stops"
//        }
//    }
    
}
