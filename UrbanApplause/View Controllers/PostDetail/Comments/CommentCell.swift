//
//  CommentCell.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-10-27.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol CommentCellDelegate: class {
    func commentCell(didSelectUser user: User)
    func commentCell(_ sender: UIButton, showMoreOptionsForComment comment: Comment, atIndexPath indexPath: IndexPath)
}

class CommentCell: UITableViewCell {
    static let reuseIdentifier = "CommentCell"
    weak var delegate: CommentCellDelegate?
    var indexPath: IndexPath?
    
    var comment: Comment? {
        didSet {
            usernameButton.setTitle(comment?.User?.username, for: .normal)
            dateLabel.text = comment?.createdAt.uiFormat
            contentLabel.text = comment?.content
        }
    }
    
    lazy var usernameButton: UIButton = {
        let label = UAButton(title: "", target: self, action: #selector(didSelectUser(_:)))
        return label
    }()
    
    lazy var dateLabel: UILabel = {
        let label = UILabel(type: .small)
        label.textColor = UIColor.systemGray
        return label
    }()
    lazy var moreButton = IconButton(image: UIImage(systemName: "ellipsis"),
                                     target: self,
                                     action: #selector(showMoreOptions(_:)))

    lazy var metaStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [usernameButton, dateLabel, NoFrameView(), moreButton])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var contentLabel = UILabel(type: .body)
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [metaStackView, contentLabel])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(stackView)
        stackView.fillWithinMargins(view: contentView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func didSelectUser(_: Any) {
        guard let user = comment?.User else { return }
        delegate?.commentCell(didSelectUser: user)
    }
    
    @objc func showMoreOptions(_ sender: UIButton) {
        guard let comment = self.comment, let indexPath = self.indexPath else { return }
        delegate?.commentCell(sender, showMoreOptionsForComment: comment, atIndexPath: indexPath)
    }
}
