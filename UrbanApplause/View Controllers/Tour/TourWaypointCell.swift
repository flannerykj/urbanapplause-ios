//
//  TourWaypointCell.swift
//  UrbanApplause
//
//  Created by Flann on 2020-12-04.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import Shared
import CoreLocation

class TourWaypointCell: UITableViewCell {
    let label = UILabel(type: .label)
    let subtitleLabel = UILabel(type: .small)
    
    
    private lazy var stackView: UIStackView = {
        let detailDividerLine = UIView()
        detailDividerLine.translatesAutoresizingMaskIntoConstraints = false
        let view = UIStackView(arrangedSubviews: [label, subtitleLabel, detailDividerLine, detailView])
        view.axis = .vertical
        return view
    }()
    
    private lazy var detailView: UIView = {
        let view = UIView()
//        view.backgroundColor = UIColor.systemPink
        return view
    }()
    
    func configureForViewModel(_ viewModel: WaypointViewModel, currentLocation: CLLocation?) {
        label.text = viewModel.post.Location?.street_address
        
        subtitleLabel.text = getDistanceText(from: viewModel.distance)
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.text = "placeholder"
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        detailView.snp.makeConstraints { make in
            make.height.equalTo(0)
        }
        label.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        detailView.snp.updateConstraints { make in
            make.height.equalTo(selected ? 200 : 0)
        }
        invalidateIntrinsicContentSize()
        contentView.layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        detailView.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func getDistanceText(from distance: CLLocationDistance?) -> String? {
        if distance == 0 { return "Current location" }
        guard let roundedDistance = distance?.rounded() else { return nil }
        
        if roundedDistance == 1 {
            return "1 meter"
        } else if roundedDistance < 500 {
            // Show in meters
            return "\(roundedDistance) meters"
        } else {
            let roundedKM = (roundedDistance / 1000).rounded()
            if roundedKM == 1000 {
                return "1 km"
            } else {
                return "\(roundedKM) km"
            }
        }
    }
}
    

