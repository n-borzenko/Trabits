//
//  AppCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/01/2024.
//

import UIKit
import Combine

@MainActor
final class AppCoordinator {
  var childCoordinators: [any Coordinator] = []
  var window: UIWindow

  private var cancellables = Set<AnyCancellable>()

  init(window: UIWindow) {
    self.window = window

    UserDefaults.standard
      .publisher(for: \.wasOnboardingShown)
      .sink { [weak self] wasOnboardingShown in
        if wasOnboardingShown {
          self?.setupMainCoordinator()
        } else {
          self?.setupOnboardingCoordinator()
        }
      }
      .store(in: &cancellables)
  }

  private func setupOnboardingCoordinator() {
    let onboardingCoordinator = OnboardingCoordinator()
    childCoordinators.append(onboardingCoordinator)
    onboardingCoordinator.start()
    window.rootViewController = onboardingCoordinator.rootViewController
  }

  private func setupMainCoordinator() {
    let mainCoordinator = MainCoordinator()
    childCoordinators.append(mainCoordinator)
    mainCoordinator.start()
    window.rootViewController = mainCoordinator.rootViewController
  }

  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}
