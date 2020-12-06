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
import MapKit
import Combine

enum TourInfoSection: Int, CaseIterable {
    case overview
    case waypoints
}

class TourInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var annotations: [Post] = []
    private let tourDataStream: TourMapDataStreaming
    private var cancellables = Set<AnyCancellable>()
    
    init(tourDataStream: TourMapDataStreaming) {
        self.tourDataStream = tourDataStream
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TourWaypointCell.self, forCellReuseIdentifier: "TourWaypointCell")
        tableView.register(TourOverviewCell.self, forCellReuseIdentifier: "TourOverviewCell")
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
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
        
        subscribeToDataStream()
    }
    
    private func subscribeToDataStream() {
        tourDataStream.annotationsStream
            .sink(receiveValue: { annotations in
                DispatchQueue.main.async {
                    self.annotations = annotations
                    self.tableView.reloadData()
                }
            })
            .store(in: &cancellables)
        
        tourDataStream.selectedAnnotationIndex
            .sink { index in
            if let i = index {
                let indexPath = IndexPath(row: i, section: TourInfoSection.waypoints.rawValue)
                if self.tableView.indexPathForSelectedRow != indexPath {
                    self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
                }
            } else {
                self.tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
            }
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
        }
        .store(in: &cancellables)

    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TourInfoSection.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = TourInfoSection.allCases[section]
        switch section {
        case .overview:
            return 1
        case .waypoints:
            return annotations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = TourInfoSection.allCases[indexPath.section]
        switch section {
        case .overview:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TourOverviewCell") as! TourOverviewCell
            cell.configureForCollection(tourDataStream.collection)
            return cell
        case .waypoints:
            let post = annotations[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "TourWaypointCell", for: indexPath) as! TourWaypointCell
            cell.configureForPost(post, currentLocation: nil)
            return cell
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = TourInfoSection.allCases[section]
        switch sectionType {
        case .overview:
            return nil
        case .waypoints:
            return TableSectionHeaderView(height: 100, title: "Waypoints")
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let currentSelectedIndexPath = tableView.indexPathForSelectedRow
        if indexPath == currentSelectedIndexPath {
            tourDataStream.setSelectedPostIndex(nil)
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let sectionType = TourInfoSection.allCases[indexPath.section]
        switch sectionType {
        case .overview:
            break
        case .waypoints:
            tourDataStream.setSelectedPostIndex(indexPath.row)
        }
    }
    
}


class ExpandedPostCell: UITableViewCell {
    
    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundColor = .red
    }
}
