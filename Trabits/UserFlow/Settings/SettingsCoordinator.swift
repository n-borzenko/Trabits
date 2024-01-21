//
//  SettingsCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import UIKit

final class SettingsCoordinator: Coordinator {
  var childCoordinators: [any Coordinator] = []
  private lazy var settingsViewController = UIViewController()
  lazy var rootViewController = UINavigationController(rootViewController: settingsViewController)
  
  func start() {
    rootViewController.navigationBar.prefersLargeTitles = true
    settingsViewController.title = "Settings"
    settingsViewController.view.backgroundColor = .systemPink
  }
}
