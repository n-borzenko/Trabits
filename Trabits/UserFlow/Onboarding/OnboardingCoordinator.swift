//
//  OnboardingCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import UIKit

final class OnboardingCoordinator: Coordinator {
  var childCoordinators: [any Coordinator] = []
  lazy var rootViewController = UIViewController()
  
  func start() {
    rootViewController.view.backgroundColor = .yellow
    
    var buttonConfiguration = UIButton.Configuration.bordered()
    buttonConfiguration.title = "Done"
    let doneButton = UIButton(configuration: buttonConfiguration, primaryAction: UIAction() { _ in
      UserDefaults.standard.wasOnboardingShown = true
    })
    
    rootViewController.view.addPinnedSubview(doneButton)
  }
}
