//
//  UserProfileViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//
import UIKit
import Shared
import Combine

enum ProfileTableRow: Int, CaseIterable {
    case account
    case posted
    case applauded
    case visited
    
    var title: String {
        switch self {
        case .account:
            return "Account"
        case .posted:
            return "Posted"
        case .applauded:
            return "Applauded"
        case .visited:
            return "Visited"
        }
    }
}

class ProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UAImagePickerDelegate {
    
    private var subscriptions = Set<AnyCancellable>()
    private lazy var imagePicker = UAImagePicker(presentationController: self, delegate: self)
    var appContext: AppContext
    var user: User
    
    var isAuthUser: Bool {
        if let userId = self.appContext.store.user.data?.id,
            userId == user.id {
            return true
        }
        return false
    }
    
    lazy var tableView: UATableView = {
        let tableView = UATableView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ProfileTableCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.backgroundColor = UIColor.secondarySystemBackground
        return tableView
    }()

    init(user: User, appContext: AppContext) {
        self.appContext = appContext
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Views
    lazy var nameLabel: UILabel = UILabel(type: .h8)
    lazy var bioLabel: UILabel = UILabel(type: .body)
    lazy var memberSinceLabel: UILabel = UILabel(type: .body)
    
    let refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshUserProfile(sender:)), for: .valueChanged)
        control.backgroundColor = UIColor.secondarySystemBackground
        return control
    }()

    let profileIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle"))
        imageView.contentMode = .scaleAspectFit
        imageView.snp.makeConstraints { make in
            make.height.width.equalTo(48)
        }
        let gr = UITapGestureRecognizer(target: self, action: #selector(editProfilePhoto(_:)))
        imageView.addGestureRecognizer(gr)
        return imageView
    }()

    lazy var headerTextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, bioLabel, memberSinceLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [profileIcon, headerTextStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .top
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 24, left: 12, bottom: 8, right: 12)
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemBackground
        navigationItem.title = isAuthUser ? "Profile" : self.user.username
        if isAuthUser {
            let editButton = UIBarButtonItem(barButtonSystemItem: .edit,
                                             target: self, action: #selector(pressedEdit(_:)))
            navigationItem.rightBarButtonItem = editButton
        }
        view.addSubview(headerStackView)
        headerStackView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(headerStackView.snp.bottom).offset(16)
            $0.leading.trailing.equalTo(view)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(0)
        }
        updateLabels()
        
        tableView.contentSizeStream
            .sink { size in
                self.tableView.snp.updateConstraints { make in
                    make.height.equalTo(size.height)
                }
                self.tableView.layoutIfNeeded()
            }
            .store(in: &subscriptions)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }
    
    // MARK: - ImagePickerDelegate
    func imagePicker(pickerController: UIImagePickerController?, didSelectImage imageData: Data?, dataWithEXIF: Data?) {

    }
    
    func imagePickerDidCancel(pickerController: UIImagePickerController?) {
        
    }
    
    
    @objc func refreshUserProfile(sender: UIRefreshControl) {
        let endpoint = PrivateRouter.getUser(id: user.id)
        _ = appContext.networkService.request(endpoint) { (result: UAResult<UserContainer>) in
            
            DispatchQueue.main.async {
                sender.endRefreshing()
                switch result {
                case .success(let userContainer):
                    if self.isAuthUser {
                        self.appContext.store.user.data = userContainer.user
                    }
                    self.user = userContainer.user
                    self.updateLabels()
                case .failure(let error):
                    log.error(error)
                }
            }
        }
    }
    
    func updateLabels() {
        for view in headerTextStackView.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        nameLabel.text = user.username
        headerTextStackView.addArrangedSubview(nameLabel)
        
        if let bio = user.bio, bio.count > 0 {
            bioLabel.text = bio
            bioLabel.font = TypographyStyle.body.font
            headerTextStackView.addArrangedSubview(bioLabel)
        }
        if let dateString = user.createdAt?.justTheDate {
            memberSinceLabel.text = "\(Strings.MemberSinceFieldLabel) \(dateString)"
            headerTextStackView.addArrangedSubview(memberSinceLabel)
        }
    }
   
    @objc func pressedEdit(_ sender: UIBarButtonItem) {
        let vc = EditProfileViewController(appContext: appContext)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func editProfilePhoto(_ sender: UIView) {
        let picker = self.imagePicker.showActionSheet(from: sender)
    }

    private lazy var tableSections: [[ProfileTableRow]] = {
        let publicItems: [ProfileTableRow] = [
            .applauded, .posted, .visited
        ]
        let privateItems: [ProfileTableRow] = [
            .account
        ]
        return isAuthUser ? [privateItems, publicItems] : [publicItems]
    }()
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableSections[safe: section]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section > 0 else { return 0 }
        return 32
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 32))
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableCell", for: indexPath)
        cell.backgroundColor = .systemBackground
        let rowType = tableSections[safe: indexPath.section]?[safe: indexPath.row]
        cell.textLabel?.text = rowType?.title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let rowType = tableSections[safe: indexPath.section]?[safe: indexPath.row] else { return }

        switch rowType {
        case .account:
            let vc = AccountViewController(appContext: appContext)
            navigationController?.pushViewController(vc, animated: true)
            return
        case .applauded:
            let viewModel = DynamicPostListViewModel(filterForUserApplause: user, appContext: appContext)
            showPostListController(viewModel: viewModel, controllerTitle: "Applauded")

        case .posted:
            let viewModel = DynamicPostListViewModel(filterForPostedBy: user, filterForArtist: nil, filterForQuery: nil,
                                                       appContext: appContext)
            showPostListController(viewModel: viewModel, controllerTitle: "Posted")

        case .visited:
            let viewModel = DynamicPostListViewModel(filterForVisitedBy: user, appContext: appContext)
            showPostListController(viewModel: viewModel, controllerTitle: "Visited")
        }
        
    }
    
    
    private func showPostListController(viewModel: DynamicPostListViewModel, controllerTitle: String) {
        let postsController = PostListViewController(viewModel: viewModel, appContext: appContext)
        postsController.navigationItem.title = controllerTitle
        navigationController?.pushViewController(postsController, animated: true)
    }
}

extension ProfileViewController: EditProfileDelegate {
    func didUpdateUser(_ user: User) {
        self.user = user
        self.updateLabels()
    }
}
extension ProfileViewController: ToolbarTabItemDelegate {
    
}
