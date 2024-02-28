//
//  StatisticsPaginationViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 19/02/2024.
//

import UIKit
import SwiftUI
import Combine
import CoreData

struct StatisticsPaginationViewControllerWrapper: UIViewControllerRepresentable {
  @Environment(\.managedObjectContext) var managedObjectContext
  @EnvironmentObject var statisticsRouter: StatisticsRouter

  func makeUIViewController(context: Context) -> StatisticsPaginationViewController {
    let controller = StatisticsPaginationViewController(statisticsRouter: statisticsRouter, context: managedObjectContext)
    return controller
  }

  func updateUIViewController(_ uiViewController: StatisticsPaginationViewController, context: Context) { }
}

class StatisticsPaginationViewController: UIViewController {
  private var statisticsRouter: StatisticsRouter
  private var context: NSManagedObjectContext

  private var pageViewController: PageViewController!
  private var subtitleViewContainer: UIHostingController<StatisticsSubtitleView>!

  private var cancellable: AnyCancellable?

  init(statisticsRouter: StatisticsRouter, context: NSManagedObjectContext) {
    self.statisticsRouter = statisticsRouter
    self.context = context
    super.init(nibName: nil, bundle: nil)

    setupViews()

    cancellable = statisticsRouter.$currentState.sink { [weak self] newValue in
      guard let self else { return }
      subtitleViewContainer.rootView.unit = newValue.contentType
      subtitleViewContainer.rootView.subtitle = StatisticsRouter.generateTitle(contentType: newValue.contentType, date: newValue.date)
      currentDateUpdateHandler(newState: newValue)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    cancellable?.cancel()
    cancellable = nil
  }
}

extension StatisticsPaginationViewController {
  private func setupViews() {
    view.backgroundColor = .systemBackground

    let subtitleView = StatisticsSubtitleView(
      unit: statisticsRouter.currentState.contentType,
      subtitle: StatisticsRouter.generateTitle(contentType: statisticsRouter.currentState.contentType, date: statisticsRouter.currentState.date),
      previousSelectionHandler: { [weak self] in
        guard let self, let newDate = getCurrentPageDate(adjustment: -1) else { return }
        statisticsRouter.currentState.date = newDate
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
      },
      nextSelectionHandler: { [weak self] in
        guard let self, let newDate = getCurrentPageDate(adjustment: 1) else { return }
        statisticsRouter.currentState.date = newDate
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
      }
    )

    subtitleViewContainer = UIHostingController(rootView: subtitleView)
    addChild(subtitleViewContainer)
    subtitleViewContainer.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(subtitleViewContainer.view)
    subtitleViewContainer.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    subtitleViewContainer.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    subtitleViewContainer.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    subtitleViewContainer.didMove(toParent: self)

    let pageContainerView = UIView()
    pageContainerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pageContainerView)
    pageContainerView.topAnchor.constraint(equalTo: subtitleViewContainer.view.bottomAnchor).isActive = true
    pageContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    pageContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    pageContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

    pageViewController = PageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    pageViewController.delegate = self
    pageViewController.dataSource = self
    pageViewController.accessibilityScrollDelegate = self

    addChild(pageViewController)
    pageContainerView.addPinnedSubview(pageViewController.view)

    let initialControllers = [generatePageView(contentType: statisticsRouter.currentState.contentType, date: statisticsRouter.currentState.date)]
    pageViewController.setViewControllers(initialControllers, direction: .forward, animated: false)
    pageViewController.didMove(toParent: self)
  }
}

extension StatisticsPaginationViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard completed, let date = getCurrentPageDate() else { return }
    statisticsRouter.currentState.date = date
  }
}

extension StatisticsPaginationViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    generatePageView(contentType: statisticsRouter.currentState.contentType, date: statisticsRouter.currentState.date, adjustment: -1)
  }

  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    generatePageView(contentType: statisticsRouter.currentState.contentType, date: statisticsRouter.currentState.date, adjustment: 1)
  }
}

extension StatisticsPaginationViewController: AccessibilityPageScrollDelegate {
  func selectNextPage(direction: UIPageViewController.NavigationDirection) -> Bool {
    guard let newDate = getCurrentPageDate(adjustment: direction == .forward ? 1 : -1) else { return false }

    currentDateUpdateHandler(
      newState: StatisticsRouterState(contentType: statisticsRouter.currentState.contentType, date: newDate)
    ) { [weak self] _ in
      guard let self else { return }
      statisticsRouter.currentState.date = newDate
      let message = "\(StatisticsRouter.generateTitle(contentType: statisticsRouter.currentState.contentType, date: newDate)) is selected"
      UIAccessibility.post(notification: .pageScrolled, argument: message)
    }

    return true
  }
}

extension StatisticsPaginationViewController {
  func currentDateUpdateHandler(newState: StatisticsRouterState, completion: ((Bool) -> Void)? = nil) {
    if newState.contentType != statisticsRouter.currentState.contentType {
      let initialControllers = [generatePageView(contentType: newState.contentType, date: newState.date)]
      pageViewController.setViewControllers(initialControllers, direction: .forward, animated: false, completion: completion)
      return
    }

    guard let currentPageDate = getCurrentPageDate(),
          !isDateInCurrentPageInterval(contentType: newState.contentType, testDate: newState.date) else { return }
    let direction: UIPageViewController.NavigationDirection = newState.date > currentPageDate ? .forward : .reverse
    let initialControllers = [generatePageView(contentType: newState.contentType, date: newState.date)]
    pageViewController.setViewControllers(initialControllers, direction: direction, animated: true, completion: completion)
  }
}

extension StatisticsPaginationViewController {
  private func generatePageView(contentType: StatisticsContentType, date: Date, adjustment: Int = 0) -> UIViewController {
    switch contentType {
    case .weekly:
      guard let interval = Calendar.current.weekInterval(for: date, adjustment: adjustment) else { return UIViewController() }
      let weekData = StatisticsWeekData(week: interval, context: context)
      return UIHostingController(rootView: StatisticsWeekView(weekData: weekData))
    case .monthly:
      guard let interval = Calendar.current.monthInterval(for: date, adjustment: adjustment),
            let monthData = StatisticsMonthData(month: interval, context: context) else { return UIViewController() }
      return UIHostingController(rootView: StatisticsMonthView(monthData: monthData))
    }
  }

  private func getCurrentPageDate(adjustment: Int = 0) -> Date? {
    switch statisticsRouter.currentState.contentType {
    case .weekly:
      guard let controller = pageViewController.viewControllers?.first as? UIHostingController<StatisticsWeekView> else { return nil }
      let startDate = controller.rootView.weekData.week.start
      guard let date = Calendar.current.weekInterval(for: startDate, adjustment: adjustment)?.start else { return nil }
      return date
    case .monthly:
      guard let controller = pageViewController.viewControllers?.first as? UIHostingController<StatisticsMonthView> else { return nil }
      let startDate = controller.rootView.monthData.month.start
      guard let date = Calendar.current.monthInterval(for: startDate, adjustment: adjustment)?.start else { return nil }
      return date
    }
  }

  private func isDateInCurrentPageInterval(contentType: StatisticsContentType, testDate: Date) -> Bool {
    switch statisticsRouter.currentState.contentType {
    case .weekly:
      guard let controller = pageViewController.viewControllers?.first as? UIHostingController<StatisticsWeekView> else { return false }
      return testDate >= controller.rootView.weekData.week.start && testDate < controller.rootView.weekData.week.end
    case .monthly:
      guard let controller = pageViewController.viewControllers?.first as? UIHostingController<StatisticsMonthView> else { return false }
      return testDate >= controller.rootView.monthData.month.start && testDate < controller.rootView.monthData.month.end
    }
  }
}
