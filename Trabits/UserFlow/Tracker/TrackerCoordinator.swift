//
//  TrackerCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import UIKit

final class TrackerCoordinator: Coordinator {
  private weak var mainCoordinator: MainCoordinator?
  var childCoordinators: [any Coordinator] = []
  private lazy var trackerContainerViewController = TrackerContainerViewController(trackerCoordinator: self)
  lazy var rootViewController = UINavigationController(rootViewController: trackerContainerViewController)

  init(mainCoordinator: MainCoordinator? = nil) {
    self.mainCoordinator = mainCoordinator
  }

  func start() {
    rootViewController.navigationBar.prefersLargeTitles = false
  }

  func popToRoot() {
    trackerContainerViewController.chooseToday()
  }

  func navigateToStructureTab() {
    mainCoordinator?.selectedTab = .structure
  }
}
