//
//  MainCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import UIKit

@MainActor
protocol Coordinator {
  associatedtype ViewController: UIViewController
  var rootViewController: ViewController { get set }
  var childCoordinators: [any Coordinator] { get set }
  func start()
  func popToRoot()
}

extension Coordinator {
  func start() {}
  func popToRoot() {}
}

final class MainCoordinator: NSObject, Coordinator, UITabBarControllerDelegate {
  enum TabRoute: Hashable {
    case tracker
    case statistics
    case structure
    case settings
  }

  var childCoordinators: [any Coordinator] = []
  lazy var rootViewController = UITabBarController()

  private let tabs: [TabRoute] = [.tracker, .statistics, .structure, .settings]
  var selectedTab: TabRoute = .tracker {
    didSet {
      let index = tabs.firstIndex { $0 == selectedTab } ?? 0
      if selectedTab == oldValue {
        childCoordinators[index].popToRoot()
      } else {
        rootViewController.selectedIndex = index
      }
    }
  }

  func start() {
    setupViews()
    setupCoordinators()
  }

  private func setupCoordinators() {
    var viewControllers: [UIViewController] = []

    for i in 0..<tabs.count {
      switch tabs[i] {
      case .tracker:
        let trackerCoordinator = TrackerCoordinator(mainCoordinator: self)
        childCoordinators.append(trackerCoordinator)
        trackerCoordinator.rootViewController.tabBarItem = UITabBarItem(title: "Tracker", image: UIImage(systemName: "checklist"), tag: i)
        viewControllers.append(trackerCoordinator.rootViewController)
      case .statistics:
        let statisticsCoordinator = StatisticsCoordinator(mainCoordinator: self)
        childCoordinators.append(statisticsCoordinator)
        statisticsCoordinator.rootViewController.tabBarItem = UITabBarItem(
          title: "Statistics", image: UIImage(systemName: "chart.xyaxis.line"), tag: i
        )
        viewControllers.append(statisticsCoordinator.rootViewController)
      case .structure:
        let structureCoordinator = StructureCoordinator()
        childCoordinators.append(structureCoordinator)
        structureCoordinator.rootViewController.tabBarItem = UITabBarItem(
          title: "My Habits", image: UIImage(systemName: "rectangle.stack.badge.plus"), tag: i
        )
        viewControllers.append(structureCoordinator.rootViewController)
      case .settings:
        let settingsCoordinator = SettingsCoordinator()
        childCoordinators.append(settingsCoordinator)
        settingsCoordinator.rootViewController.tabBarItem = UITabBarItem(
          title: "Settings", image: UIImage(systemName: "gearshape.fill"), tag: i
        )
        viewControllers.append(settingsCoordinator.rootViewController)
      }
    }

    rootViewController.setViewControllers(viewControllers, animated: false)
    for childCoordinator in childCoordinators {
      childCoordinator.start()
    }
  }

  private func setupViews() {
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithOpaqueBackground()
    tabBarAppearance.backgroundColor = .systemBackground
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

    let lineBorderView = UIView()
    lineBorderView.backgroundColor = .neutral30
    lineBorderView.translatesAutoresizingMaskIntoConstraints = false
    rootViewController.tabBar.addSubview(lineBorderView)

    lineBorderView.topAnchor.constraint(equalTo: rootViewController.tabBar.topAnchor).isActive = true
    lineBorderView.leadingAnchor.constraint(equalTo: rootViewController.tabBar.leadingAnchor).isActive = true
    lineBorderView.trailingAnchor.constraint(equalTo: rootViewController.tabBar.trailingAnchor).isActive = true
    lineBorderView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true

    rootViewController.delegate = self
  }

  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    guard viewController.tabBarItem.tag < tabs.count else { return }
    selectedTab = tabs[viewController.tabBarItem.tag]
  }
}
