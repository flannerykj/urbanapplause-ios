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
    let label = UILabel()
    let subtitleLabel = UILabel()
    
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [label, subtitleLabel, detailView])
        view.axis = .vertical
        view.spacing = 16
        return view
    }()
    
    private lazy var detailView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemPink
        return view
    }()
    
    func configureForPost(_ post: Post, currentLocation: CLLocation?) {
        label.text = post.Location?.street_address
        
        if let postLocation = post.Location,
           let distance = currentLocation?.distance(from: postLocation.clLocation) {
            subtitleLabel.text = "\(distance) meters"
        } else {
            subtitleLabel.text = ""
        }
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
}
    

