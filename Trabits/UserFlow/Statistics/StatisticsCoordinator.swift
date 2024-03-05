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

  var itemTitle: String {
    switch self {
    case .weekly: return "week"
    case .monthly: return "month"
    }
  }
}

protocol StatisticsRouterDelegate: AnyObject {
  func navigateToStructureTab()
}

struct StatisticsRouterState {
  var contentType: StatisticsContentType
  var date: Date
}

final class StatisticsRouter: ObservableObject {
  @Published var pickerContentType = StatisticsContentType.weekly
  @Published var currentState = StatisticsRouterState(contentType: .weekly, date: Date())

  weak var delegate: StatisticsRouterDelegate?

  func navigateToStructureTab() {
    delegate?.navigateToStructureTab()
  }

  static func generateTitle(contentType: StatisticsContentType, date: Date) -> String {
    switch contentType {
    case .weekly:
      guard let interval = Calendar.current.weekInterval(for: date),
            let endDate = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) else { return "" }
      let startDateString = interval.start.formatted(date: .abbreviated, time: .omitted)
      let endDateString = endDate.formatted(date: .abbreviated, time: .omitted)
      return "\(startDateString) - \(endDateString)"

    case .monthly:
      return Calendar.current.monthSymbols[Calendar.current.component(.month, from: date) - 1]
    }
  }
}

extension StatisticsRouter: DatePickerViewControllerDelegate {
  func dateSelectionHandler(date: Date) {
    currentState.date = date
    let message = "\(StatisticsRouter.generateTitle(contentType: currentState.contentType, date: date)) is selected"
    UIAccessibility.post(notification: .pageScrolled, argument: message)
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
    statisticsRouter.currentState = StatisticsRouterState(contentType: .weekly, date: Date())
    statisticsRouter.pickerContentType = .weekly
  }

  func navigateToStructureTab() {
    mainCoordinator?.selectedTab = .structure
  }
}
