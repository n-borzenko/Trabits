//
//  OnboardingCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import SwiftUI

final class OnboardingCoordinator: Coordinator {
  var childCoordinators: [any Coordinator] = []
  
  lazy var rootViewController: UIViewController = {
    let onboardingView = OnboardingView()
    return UIHostingController(rootView: onboardingView)
  }()
}
