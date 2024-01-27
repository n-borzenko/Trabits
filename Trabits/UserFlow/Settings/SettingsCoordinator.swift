//
//  SettingsCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import SwiftUI

final class SettingsRouter: ObservableObject {
  @Published var path = NavigationPath()
}

final class SettingsCoordinator: Coordinator {
  var childCoordinators: [any Coordinator] = []
  
  private let settingsRouter = SettingsRouter()
  
  lazy var rootViewController: UIViewController = {
    let settingsView = SettingsView()
      .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
      .environmentObject(settingsRouter)
    
    return UIHostingController(rootView: settingsView)
  }()
  
  func popToRoot() {
    settingsRouter.path.removeLast(settingsRouter.path.count)
  }
}
