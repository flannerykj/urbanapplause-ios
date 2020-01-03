//
//  TabbedToolbarViewController.swift
//  UrbanApplause
//
//  Created by Flannery Jefferson on 2020-01-02.
//  Copyright © 2020 Flannery Jefferson. All rights reserved.
//

import Foundation
import UIKit

protocol TabContentViewController: UIViewController {
    var tabContentDelegate: TabContentDelegate? { get set }
    var contentScrollView: UIScrollView? { get }
}
protocol TabContentDelegate: class {
    func didUpdateContentSize(controller: TabContentViewController, height: CGFloat)
}
class TabbedToolbarViewController: UIViewController {
    var lastTabContentScrollOffset: CGFloat?
    var lastContainerScrollOffset: CGFloat?

    var visibleTabItems: [ToolbarTabItem]
    var mainCoordinator: MainCoordinator
    var activeControllerContentHeight: CGFloat?
    
    var tabButtons: [ToolbarTabButton] = []
    var tabControllers: [TabContentViewController] = []
    var activeTabIndex: Int = 0 {
        didSet {
            self.updateActiveTab()
        }
    }
    var headerContent: UIView
    
    lazy var headerView: UIView = {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.layoutMargins = StyleConstants.defaultMarginInsets
        headerView.addSubview(headerContent)
        headerContent.fillWithinMargins(view: headerView)
        return headerView
    }()
    
    init(headerContent: UIView, tabItems: [ToolbarTabItem], mainCoordinator: MainCoordinator) {
        self.mainCoordinator = mainCoordinator
        self.visibleTabItems = tabItems
        self.headerContent = headerContent
        super.init(nibName: nil, bundle: nil)

        var i: Int = 0
        for tabItem in visibleTabItems {
            log.debug(tabItem)
            let tabVC = tabItem.viewController
            tabVC.tabContentDelegate = self
            tabControllers.append(tabVC)

            let tabButton = ToolbarTabButton(title: tabItem.title,
                                                   icon: tabItem.icon,
                                                   activeTint: tabItem.tint,
                                                   target: self,
                                                   action: #selector(didSelectTab(sender:)))
            tabButton.tag = i
            tabButtons.append(tabButton)
            tabVC.didMove(toParent: self)
            i += 1
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var tabBarStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: tabButtons)
        stackView.axis = .horizontal
        stackView.spacing = StyleConstants.contentPadding
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = UIEdgeInsets(top: 0,
                                               left: StyleConstants.contentMargin,
                                               bottom: 0,
                                               right: StyleConstants.contentMargin)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    lazy var activeTabUnderlineLeftConstraint =
        activeTabUnderline.leftAnchor.constraint(equalTo: tabButtonsScrollView.leftAnchor, constant: 0)
    lazy var activeTabUnderlineWidthConstraint = activeTabUnderline.widthAnchor.constraint(equalToConstant: 100)

    lazy var tabButtonsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(tabBarStackView)
        scrollView.accessibilityIdentifier = "onboardingScrollView"
        tabBarStackView.fill(view: scrollView)
        scrollView.addSubview(activeTabUnderline)
        tabBarStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    lazy var controllerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = 0
        return stackView
    }()
    lazy var controllersScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(controllerStackView)
        scrollView.isScrollEnabled = false
        scrollView.accessibilityIdentifier = "onboardingScrollView"
        controllerStackView.fill(view: scrollView)
        NSLayoutConstraint.activate([
            controllerStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
            ])
        
        for tabVC in self.tabControllers {
            tabVC.view.translatesAutoresizingMaskIntoConstraints = false
            addChild(tabVC)
            controllerStackView.addArrangedSubview(tabVC.view)
            tabVC.didMove(toParent: self)
            let screenSize: CGRect = UIScreen.main.bounds
            tabVC.contentScrollView?.isScrollEnabled = false
            NSLayoutConstraint.activate([
                tabVC.view.widthAnchor.constraint(equalToConstant: screenSize.width),
                tabVC.view.bottomAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.bottomAnchor),
                tabVC.view.topAnchor.constraint(equalTo: scrollView.topAnchor)
            ])
        }

        scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
        scrollView.contentOffset = CGPoint(x: 0, y: 0)
        return scrollView
    }()

    let activeTabUnderline: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 2).isActive = true
        view.backgroundColor = UIColor.backgroundLight
        return view
    }()

    lazy var tabsView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabButtonsScrollView)
        NSLayoutConstraint.activate([
            tabButtonsScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            tabButtonsScrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tabButtonsScrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tabButtonsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activeTabUnderline.heightAnchor.constraint(equalToConstant: 2),
            activeTabUnderline.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        view.backgroundColor = .systemGray6
        return view
    }()
    lazy var controllersScrollViewHeightConstraint = controllersScrollView.heightAnchor.constraint(equalToConstant:
        self.view.frame.height - tabsView.bounds.height - headerView.bounds.height)
    
    lazy var containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(headerView)
        scrollView.addSubview(tabsView)
        scrollView.addSubview(controllersScrollView)
        scrollView.showsVerticalScrollIndicator = false
        NSLayoutConstraint.activate([
           headerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
           headerView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
           headerView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
           headerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
           
           tabsView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
           tabsView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
           tabsView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
           tabsView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
           
           controllersScrollView.topAnchor.constraint(equalTo: tabsView.bottomAnchor),
           controllersScrollView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
           controllersScrollView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
           controllersScrollView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
           controllersScrollView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
           controllersScrollViewHeightConstraint,
           
           activeTabUnderlineLeftConstraint,
           activeTabUnderlineWidthConstraint
       ])
        return scrollView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.backgroundMain
        view.addSubview(containerScrollView)
        NSLayoutConstraint.activate([
            containerScrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            containerScrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            containerScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            containerScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        activeTabUnderline.clipsToBounds = true
        for tabButton in self.tabButtons {
            tabButton.addTarget(self, action: #selector(didSelectTab(sender:)), for: .touchUpInside)
        }
        self.activeTabIndex = 0
    }

    func calculateXOffset(forTabIndex tabIndex: Int) -> CGFloat {
        let screenSize: CGRect = UIScreen.main.bounds
        return CGFloat(tabIndex) * screenSize.width
    }
    func updateActiveTab() {
        DispatchQueue.main.async {
            let index = self.activeTabIndex
            guard self.visibleTabItems.count > 0 else { log.error("no tab items"); return }
             let nextX = self.calculateXOffset(forTabIndex: index)
            self.controllersScrollView.setContentOffset(CGPoint(x: nextX, y: 0), animated: true)
            self.tabButtons[index].isSelected = true
            var leftOffset: CGFloat = StyleConstants.contentMargin
            var activeButtonWidth: CGFloat = 100
            for button in self.tabButtons {
                if button.tag == index {
                    activeButtonWidth = button.label.attributedText?.size().width ?? 0
                    break
                } else {
                    leftOffset += button.bounds.width
                    leftOffset += self.tabBarStackView.spacing
                }
            }
            self.view.layoutIfNeeded() // Everything after this will take effect in next animation block
            var tabItemsScrollOffset = self.tabButtonsScrollView.contentOffset
            let screenWidth = self.view.frame.width
            // scroll to center selected tab IF width of all tabs greater then screen width.
            if self.tabBarStackView.bounds.width > screenWidth {
                switch leftOffset {
                case let x where x < screenWidth/2:
                    tabItemsScrollOffset.x = 0 // scroll to beginning
                case let x where x > self.tabButtonsScrollView.contentSize.width - screenWidth/2:
                    // scroll to end
                    tabItemsScrollOffset.x = self.tabButtonsScrollView.contentSize.width - screenWidth
                default:
                    // scroll to center the highlighted tab item
                    tabItemsScrollOffset.x = leftOffset - self.view.frame.width/2
                }
            }
            
            UIView.animate(withDuration: 0.5, animations: {
             self.activeTabUnderline.backgroundColor = self.visibleTabItems[index].tint ?? UIColor.darkGray
                self.activeTabUnderlineLeftConstraint.constant = leftOffset
                self.tabButtonsScrollView.contentOffset = tabItemsScrollOffset
                self.activeTabUnderlineWidthConstraint.constant = activeButtonWidth
                self.view.layoutIfNeeded()
            })
        }
         /* self.controllersScrollView.contentSize = CGSize(width: self.controllersScrollView.contentSize.width,
                                                         height: self.tabControllers[index].view.bounds.size.height) */
    }
    @objc func didSelectTab(sender: ToolbarTabButton) {
        for view in tabBarStackView.arrangedSubviews {
            if let button = view as? UIButton {
                button.isSelected = false
            }
        }
        sender.isSelected = true
        activeTabIndex = sender.tag
        let activeController = tabControllers[activeTabIndex]
        self.updateScrollHeight(contentHeight: activeController.contentScrollView?.contentSize.height ?? 0)
    }
    
    func updateScrollHeight(contentHeight: CGFloat) {
        controllersScrollViewHeightConstraint.constant = contentHeight
        // controllersScrollView.layoutIfNeeded()
        controllersScrollView.contentSize.height = contentHeight
        containerScrollView.contentSize.height = headerView.bounds.height + tabsView.bounds.height + contentHeight
    }
}

extension TabbedToolbarViewController: TabContentDelegate {
    func didUpdateContentSize(controller: TabContentViewController, height: CGFloat) {
        if controller == tabControllers[activeTabIndex] {
            self.updateScrollHeight(contentHeight: height)
        }
    }
}
