//
//  TrackerContainerViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/10/2023.
//

import UIKit
import Combine

protocol AccessibilityDayPageScrollDelegate: AnyObject {
  func selectNextPage(direction: UIPageViewController.NavigationDirection) -> Bool
}

class DayPageViewController: UIPageViewController {
  weak var accessibilityScrollDelegate: AccessibilityDayPageScrollDelegate?
  
  override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
    guard let delegate = accessibilityScrollDelegate else { return false }
    var newDirection: UIPageViewController.NavigationDirection
    switch direction {
    case .left:
      newDirection = .forward
    case .right:
      newDirection = .reverse
    default:
      return false
    }
    return delegate.selectNextPage(direction: newDirection)
  }
}

class TrackerContainerViewController: UIViewController {
  private let dataProvider = TrackerDataProvider()
  
  private var weekViewController: TrackerWeekViewController!
  private var dayPageViewController: DayPageViewController!
  
  private let underlinedContainerView = UnderlinedContainerView()
  
  private var isNegativeCollectionScrollOffset = true {
    didSet {
      underlinedContainerView.isLineVisible = !isNegativeCollectionScrollOffset
    }
  }
  
  private var areCompletedHabitsHidden: Bool = false
  
  private var cancellable: AnyCancellable?
    
  private var dateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .none
    dateFormatter.dateStyle = .long
    return dateFormatter
  }()
  
  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    
    cancellable = dataProvider.$selectedDate.sink { [weak self] newSelectedDate in
      self?.selectedDateUpdateHandler(selectedDate: newSelectedDate)
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

extension TrackerContainerViewController {
  private func setupViews() {
    view.backgroundColor = .systemBackground
    
    view.addSubview(underlinedContainerView)
    underlinedContainerView.translatesAutoresizingMaskIntoConstraints = false
    underlinedContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    underlinedContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    underlinedContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    underlinedContainerView.heightAnchor.constraint(equalToConstant: 69).isActive = true
    
    weekViewController = TrackerWeekViewController(dataProvider: dataProvider)
    addChild(weekViewController)
    weekViewController.view.translatesAutoresizingMaskIntoConstraints = false
    underlinedContainerView.appendSubview(weekViewController.view)
    weekViewController.didMove(toParent: self)
    
    let dayContainerView = UIView()
    view.addSubview(dayContainerView)
    dayContainerView.translatesAutoresizingMaskIntoConstraints = false
    dayContainerView.topAnchor.constraint(equalTo: underlinedContainerView.bottomAnchor).isActive = true
    dayContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    dayContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    dayContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    
    dayPageViewController = DayPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    dayPageViewController.delegate = self
    dayPageViewController.dataSource = self
    dayPageViewController.accessibilityScrollDelegate = self
    
    addChild(dayPageViewController)
    dayContainerView.addPinnedSubview(dayPageViewController.view)
    let dayViewController = TrackerDayViewController(date: dataProvider.selectedDate)
    dayViewController.delegate = self
    let dayPageViewInitialControllers = [dayViewController]
    dayPageViewController.setViewControllers(dayPageViewInitialControllers, direction: .forward, animated: false)
    dayPageViewController.didMove(toParent: self)
    
    navigationItem.largeTitleDisplayMode = .never
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "house"),
      style: .plain,
      target: self,
      action: #selector(chooseToday)
    )
    navigationItem.leftBarButtonItem?.title = "Choose today"
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "calendar"),
      style: .plain,
      target: self,
      action: #selector(chooseDate)
    )
    navigationItem.rightBarButtonItem?.title = "Choose date"
  }
  
  @objc private func chooseDate() {
    let datePickerController = DatePickerViewController(date: dataProvider.selectedDate)
    datePickerController.delegate = self
    let containerController = UINavigationController(rootViewController: datePickerController)
    containerController.isModalInPresentation = true
    if let sheetController = containerController.sheetPresentationController {
      sheetController.detents = [.medium()]
      sheetController.preferredCornerRadius = 24
    }

    modalPresentationStyle = .pageSheet
    present(containerController, animated: true)
  }
  
  @objc private func chooseToday() {
    dataProvider.selectedDate = Calendar.current.startOfDay(for: Date())
    UIAccessibility.post(notification: .pageScrolled, argument: "\(dataProvider.generateSelectedDateDescription()) is selected")
  }
}

extension TrackerContainerViewController: DatePickerViewControllerDelegate {
  func dateSelectionHandler(date: Date) {
    dataProvider.selectedDate = date
    UIAccessibility.post(notification: .pageScrolled, argument: "\(dataProvider.generateSelectedDateDescription()) is selected")
  }
}

extension TrackerContainerViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard completed,
          let controller = pageViewController.viewControllers?.first as? TrackerDayViewController else { return }
    dataProvider.selectedDate = controller.date
  }
}

extension TrackerContainerViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let controller = viewController as? TrackerDayViewController,
          let newDate = Calendar.current.date(byAdding: .day, value: -1, to: controller.date) else {
      return nil
    }
    let dayViewController = TrackerDayViewController(date: newDate)
    dayViewController.delegate = self
    return dayViewController
  }
 
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let controller = viewController as? TrackerDayViewController,
          let newDate = Calendar.current.date(byAdding: .day, value: 1, to: controller.date) else {
      return nil
    }
    let dayViewController = TrackerDayViewController(date: newDate)
    dayViewController.delegate = self
    return dayViewController
  }
}

extension TrackerContainerViewController: AccessibilityDayPageScrollDelegate {
  func selectNextPage(direction: UIPageViewController.NavigationDirection) -> Bool {
    guard let offset = direction == .forward ? 1 : -1,
          let newDate = Calendar.current.date(byAdding: .day, value: offset, to: dataProvider.selectedDate) else {
      return false
    }
    updateDayPageViewController(newDate: newDate) { [weak self] _ in
      guard let self else { return }
      dataProvider.selectedDate = newDate
      UIAccessibility.post(notification: .pageScrolled, argument: "\(dataProvider.generateSelectedDateDescription()) is selected")
    }
    return true
  }
}

extension TrackerContainerViewController {
  func updateDayPageViewController(newDate: Date, completion: ((Bool) -> Void)? = nil) {
    if let dayController = dayPageViewController.viewControllers?.first as? TrackerDayViewController,
       newDate != dayController.date {
      let direction: UIPageViewController.NavigationDirection = newDate > dayController.date ? .forward : .reverse
      let newDayController = TrackerDayViewController(date: newDate)
      newDayController.delegate = self
      dayPageViewController.setViewControllers([newDayController], direction: direction, animated: true, completion: completion)
    }
  }
  
  func selectedDateUpdateHandler(selectedDate: Date) {
    navigationItem.title = dateFormatter.string(from: selectedDate)
    updateDayPageViewController(newDate: selectedDate)
  }
}

extension TrackerContainerViewController: TrackerDayScrollDelegate {
  func scrollOffsetUpdated(offset: Double) {
    if offset > 0 && isNegativeCollectionScrollOffset {
      isNegativeCollectionScrollOffset = false
    } else if offset <= 0 && !isNegativeCollectionScrollOffset {
      isNegativeCollectionScrollOffset = true
    }
  }
}