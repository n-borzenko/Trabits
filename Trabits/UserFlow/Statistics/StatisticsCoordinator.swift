//
//  StatisticsCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import UIKit

final class StatisticsCoordinator: Coordinator {
  var childCoordinators: [any Coordinator] = []
  private lazy var statisticsViewController = UIViewController()
  lazy var rootViewController = UINavigationController(rootViewController: statisticsViewController)
  
  func start() {
    rootViewController.navigationBar.prefersLargeTitles = true
    statisticsViewController.title = "Statistics"
    statisticsViewController.view.backgroundColor = .green
  }
}
