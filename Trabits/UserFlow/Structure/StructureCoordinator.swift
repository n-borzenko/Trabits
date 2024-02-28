//
//  StructureCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import SwiftUI

enum StructureContentType: String, CaseIterable {
  case habits = "Habits"
  case categories = "Categories"

  var itemTitle: String {
    switch self {
    case .habits: return "habit"
    case .categories: return "category"
    }
  }
}

final class StructureRouter: ObservableObject {
  @Published var path = NavigationPath()
  @Published var selectedContentType = StructureContentType.habits
  @Published var editMode: EditMode = .inactive
}

final class StructureCoordinator: Coordinator {
  var childCoordinators: [any Coordinator] = []

  private let structureRouter = StructureRouter()

  lazy var rootViewController: UIViewController = {
    let structureView = StructureView()
      .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
      .environmentObject(structureRouter)

    return UIHostingController(rootView: structureView)
  }()

  func popToRoot() {
    structureRouter.path.removeLast(structureRouter.path.count)
    structureRouter.selectedContentType = .habits
    structureRouter.editMode = .inactive
  }
}
