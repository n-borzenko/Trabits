//
//  StatisticsCoordinator.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/01/2024.
//

import SwiftUI

enum StatisticsContentType: String, CaseIterable {
  case weekly = "Weekly"
  case monthly = "Monthly"
  case annualy = "Annualy"
  
  var itemTitle: String {
    switch self {
    case .weekly: return "week"
    case .monthly: return "month"
    case .annualy: return "year"
    }
  }
}

protocol StatisticsRouterDelegate: AnyObject {
  func navigateToStructureTab()
}

final class StatisticsRouter: ObservableObject {
  @Published var selectedContentType = StatisticsContentType.weekly
  @Published var currentDate = Date()
  
  weak var delegate: StatisticsRouterDelegate?
  
  func navigateToStructureTab() {
    delegate?.navigateToStructureTab()
  }
}

extension StatisticsRouter: DatePickerViewControllerDelegate {
  func dateSelectionHandler(date: Date) {
    currentDate = date
  }
}

final class StatisticsCoordinator: Coordinator, StatisticsRouterDelegate {
  private weak var mainCoordinator: MainCoordinator?
  var childCoordinators: [any Coordinator] = []
  
  private var statisticsRouter = StatisticsRouter()
  
  lazy var rootViewController: UIViewController = {
    let statisticsView = StatisticsView()
      .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
      .environmentObject(statisticsRouter)
    
    return UIHostingController(rootView: statisticsView)
  }()
  
  init(mainCoordinator: MainCoordinator? = nil) {
    self.mainCoordinator = mainCoordinator
    self.statisticsRouter.delegate = self
  }
  
  func popToRoot() {
    statisticsRouter.currentDate = Date()
    statisticsRouter.selectedContentType = .weekly
  }
  
  func navigateToStructureTab() {
    mainCoordinator?.selectedTab = .structure
  }
}
