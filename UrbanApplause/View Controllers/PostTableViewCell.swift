//
//  PostTableViewCell.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-04.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell {
    
    static let reuseIdentifier = "PostCell"
    
    var photoView: UIImageView = {
       let view = UIImageView()
        view.contentMode = UIView.ContentMode.scaleAspectFill
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    var artistLabel: UILabel = {
        let label = UILabel()
        label.style(as: .h2)
        return label
    }()
    var locationLabel: UILabel = {
        let label = UILabel()
        label.style(as: .h5)
        label.text = "Location label"
        return label
    }()
    var dateLabel: UILabel = {
        let label = UILabel()
        label.style(as: .h5)
        return label
    }()
    lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [photoView, artistLabel, locationLabel, dateLabel])
        
        NSLayoutConstraint.activate([
            photoView.heightAnchor.constraint(equalToConstant: 100),
            photoView.leftAnchor.constraint(equalTo: stackView.leftAnchor),
            photoView.rightAnchor.constraint(equalTo: stackView.rightAnchor)
            ])
        
        stackView.alignment = .top
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = UITableViewCell.SelectionStyle.none
        backgroundColor = UIColor.Utility.backgroundMain
        addSubview(contentStackView)
        
        // cardView constraints
        contentStackView.leftAnchor.constraint(equalTo: leftAnchor,
                                               constant: StyleConstants.contentMargin).isActive = true
        contentStackView.rightAnchor.constraint(equalTo: rightAnchor,
                                                constant: -StyleConstants.contentMargin).isActive = true
        contentStackView.topAnchor.constraint(equalTo: topAnchor,
                                              constant: StyleConstants.contentMargin).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
