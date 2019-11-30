//
//  PostCell.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2019-01-06.
//  Copyright © 2019 Flannery Jefferson. All rights reserved.
//

import UIKit

protocol PostCellDelegate: class {
    func postCell(_ cell: PostCell, didUpdatePost post: Post, atIndexPath indexPath: IndexPath)
    func postCell(_ cell: PostCell, didSelectUser user: User)
    func postCell(_ cell: PostCell, didBlockUser user: User)
    func postCell(_ cell: PostCell, didDeletePost post: Post, atIndexPath indexPath: IndexPath)
}

class PostCell: UITableViewCell {
    var indexPath: IndexPath?
    weak var delegate: PostCellDelegate?
    var mainCoordinator: MainCoordinator? {
        didSet {
            toolbarVC.mainCoordinator = mainCoordinator
        }
    }
    var subscriber: FileDownloadSubscriber? {
        willSet {
            if let subscriber = self.subscriber { // remove previous subscriber before setting new
                // self.downloadJob?.removeSubscriber(subscriber)
            }
        }
    }
    static let reuseIdentifier = "PostCell"
    
    var isLoading: Bool = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    var activityIndicator = ActivityIndicator()
    
    var downloadJob: FileDownloadJob? {
        didSet {
            guard let job = downloadJob else {
                return
            }
            self.subscriber = job.subscribe(onSuccess: { data in
                DispatchQueue.main.async {
                    self.photoView.image = UIImage(data: data)
                }
            })
        }
    }
    
    var post: Post? {
        didSet {
            toolbarVC.post = post
            if post != nil {
                isLoading = false
                artistLabel.text = post?.title
                locationLabel.text = post?.Location?.city
                usernameButton.text = post?.User?.username
                usernameButton.style(as: .link)
                dateLabel.text = post?.createdAt?.timeSince()
            }
        }
    }
    var photoView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width/4),
            view.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75)
            ])
        view.contentMode = .scaleAspectFill
        view.layer.masksToBounds = true
        return view
    }()
    
    var artistLabel: UILabel = {
        let label = UILabel()
        label.style(as: .h2)
        return label
    }()
    var locationLabel: UILabel = {
        let label = UILabel(type: .body)
        label.font = TypographyStyle.strong.font
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    var dateLabel: UILabel = {
        let label = UILabel()
        label.style(as: .body)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    lazy var usernameButton = UILabel(type: .link)
    
    lazy var usernameRow: UIStackView = {
        let postedBy = UILabel()
        postedBy.text = "Posted by "
        postedBy.style(as: .body)
        postedBy.setContentHuggingPriority(.required, for: .horizontal)
        postedBy.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        usernameButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        usernameButton.textAlignment = .left
       let stackView = UIStackView(arrangedSubviews: [postedBy, usernameButton])
        stackView.axis = .horizontal
        stackView.alignment = .firstBaseline
        stackView.distribution = .fill
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var rightContentStackView: UIStackView = {
        toolbarVC.stackView.layoutMargins.left = 0
        let stackView = UIStackView(arrangedSubviews: [usernameRow, locationLabel, dateLabel, toolbarVC.view])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var dividerView: UIView = {
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemGray4
        } else {
            view.backgroundColor = UIColor.systemGray4
        }
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var toolbarVC = PostToolbarController(mainCoordinator: mainCoordinator)
    
    lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [photoView, rightContentStackView])
        stackView.axis = .horizontal
        stackView.spacing = 24
        stackView.alignment = .top
        stackView.layoutMargins = StyleConstants.defaultPaddingInsets
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = UITableViewCell.SelectionStyle.none
        contentView.addSubview(contentStackView)
        contentView.backgroundColor = UIColor.backgroundLight
        backgroundColor = UIColor.backgroundMain
        // cardView constraints
        contentStackView.fill(view: contentView)
        toolbarVC.delegate = self
        
        addSubview(dividerView)
        
        NSLayoutConstraint.activate([
            dividerView.rightAnchor.constraint(equalTo: rightAnchor),
            dividerView.leftAnchor.constraint(equalTo: leftAnchor),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let gr = UITapGestureRecognizer(target: self, action: #selector(didSelectUser(_:)))
        usernameButton.addGestureRecognizer(gr)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
    }
    
    @objc func didSelectUser(_: Any) {
        log.debug("press in clell")
        guard let user = post?.User else { return }
        delegate?.postCell(self, didSelectUser: user)
    }
}
extension PostCell: PostToolbarDelegate {
    func postToolbar(_ toolbar: PostToolbarController, didBlockUser user: User) {
        log.debug("dib block")
        delegate?.postCell(self, didBlockUser: user)
    }
    
    func postToolbar(_ toolbar: PostToolbarController, didUpdatePost post: Post) {
        guard let indexPath = self.indexPath else { log.error("no index path set"); return }
        delegate?.postCell(self, didUpdatePost: post, atIndexPath: indexPath)
    }
    
    func postToolbar(_ toolbar: PostToolbarController, didDeletePost post: Post) {
        guard let indexPath = self.indexPath else { log.error("no index path set"); return }
        delegate?.postCell(self, didDeletePost: post, atIndexPath: indexPath)
    }

}
