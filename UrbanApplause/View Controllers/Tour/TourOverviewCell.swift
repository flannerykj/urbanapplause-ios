//
//  TourOverviewCell.swift
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


protocol TourOverviewCellDelegate: AnyObject {
    func didTapStart()
}
class TourOverviewCell: UITableViewCell {
    weak var delegate: TourOverviewCellDelegate?
    
    let titleLabel = UILabel(type: .h7)
    let titleLabelRight = UILabel(type: .h7, color: UIColor.systemGray4)
    
    lazy var titleLabelView: UIView = {
        let view = UIView()
        view.addSubview(titleLabel)
        view.addSubview(titleLabelRight)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
        }
        titleLabelRight.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(8)
        }
        return view
    }()
    
    let subtitleLabel = UILabel(type: .body)
    
    let startButton = UAButton(type: .primary, title: "Start", target: self, action: #selector(didTapStart(_:)), rightImage: UIImage(systemName: "location"))
    
    private lazy var bottomBorderLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabelView, /*subtitleLabel,*/ startButton])
        view.axis = .vertical
        view.insetsLayoutMarginsFromSafeArea = true
        view.spacing = 8
        view.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return view
    }()
    

    func configureForCollection(_ collection: Collection) {
        titleLabel.text = collection.title
        
        let waypointsCount = collection.Posts?.count ?? 0
        titleLabelRight.text = waypointsCount == 1 ? "1 stop" : "\(waypointsCount) stops"
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(stackView)
        contentView.addSubview(bottomBorderLine)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        bottomBorderLine.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.bottom.left.right.equalToSuperview()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
   
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didTapStart(_ sender: UIButton) {
        delegate?.didTapStart()
    }
}
    

