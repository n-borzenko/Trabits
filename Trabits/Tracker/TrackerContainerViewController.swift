//
//  TrackerContainerViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/10/2023.
//

import UIKit
import Combine

class TrackerContainerViewController: UIViewController {
  private let dataProvider = TrackerDataProvider()
  
  private var weekViewController: TrackerWeekViewController!
  private var dayPageViewController: UIPageViewController!
  
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
    view.backgroundColor = .backgroundColor
    
    let weekContainerView = UIView()
    view.addSubview(weekContainerView)
    weekContainerView.translatesAutoresizingMaskIntoConstraints = false
    weekContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    weekContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    weekContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    weekContainerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
    
    weekViewController = TrackerWeekViewController(dataProvider: dataProvider)
    addChild(weekViewController)
    weekContainerView.addPinnedSubview(weekViewController.view)
    weekViewController.didMove(toParent: self)
    
    let dayContainerView = UIView()
    view.addSubview(dayContainerView)
    dayContainerView.translatesAutoresizingMaskIntoConstraints = false
    dayContainerView.topAnchor.constraint(equalTo: weekContainerView.bottomAnchor, constant: 10).isActive = true
    dayContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    dayContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    dayContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    
    dayPageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    dayPageViewController.delegate = self
    dayPageViewController.dataSource = self
    
    addChild(dayPageViewController)
    dayContainerView.addPinnedSubview(dayPageViewController.view)
    let dayPageViewInitialControllers = [TrackerDayViewController(date: dataProvider.selectedDate)]
    dayPageViewController.setViewControllers(dayPageViewInitialControllers, direction: .forward, animated: false)
    dayPageViewController.didMove(toParent: self)
    
    navigationItem.largeTitleDisplayMode = .never
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "calendar"),
      style: .plain,
      target: self,
      action: #selector(selectDate)
    )
    
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "line.3.horizontal.decrease"),
      menu: generateFilteringMenu()
    )
  }
  
  private func generateFilteringMenu() -> UIMenu {
    let showHabitsAction = UIAction(
      title: "Show all habits",
      image: UIImage(systemName: "checklist"),
      state: areCompletedHabitsHidden ? .off : .on,
      handler: { [weak self] _ in
        self?.toggleCompletedHabitsVisibility(areHidden: false)
      }
    )
    
    let hideHabitsAction = UIAction(
      title: "Hide completed habits",
      image: UIImage(systemName: "checkmark.circle.badge.xmark"),
      state: areCompletedHabitsHidden ? .on : .off,
      handler: { [weak self] _ in
        self?.toggleCompletedHabitsVisibility(areHidden: true)
      }
    )
    
    return UIMenu(
      image: UIImage(systemName: "line.3.horizontal.decrease"),
      children: [showHabitsAction, hideHabitsAction]
    )
  }
  
  @objc private func selectDate() {
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
  
  @objc private func toggleCompletedHabitsVisibility(areHidden: Bool) {
    areCompletedHabitsHidden = areHidden
    guard let filteringBarButton = navigationItem.rightBarButtonItem else { return }
    filteringBarButton.menu = generateFilteringMenu()
  }
}

extension TrackerContainerViewController: DatePickerViewControllerDelegate {
  func dateSelectionHandler(date: Date) {
    dataProvider.selectedDate = date
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
    return TrackerDayViewController(date: newDate)
  }
 
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let controller = viewController as? TrackerDayViewController,
          let newDate = Calendar.current.date(byAdding: .day, value: 1, to: controller.date) else {
      return nil
    }
    return TrackerDayViewController(date: newDate)
  }
}

extension TrackerContainerViewController {
  func selectedDateUpdateHandler(selectedDate: Date) {
    navigationItem.title = dateFormatter.string(from: selectedDate)
    
    if let dayController = dayPageViewController.viewControllers?.first as? TrackerDayViewController,
       selectedDate != dayController.date {
      let direction: UIPageViewController.NavigationDirection = selectedDate > dayController.date ? .forward : .reverse
      let newDayController = TrackerDayViewController(date: selectedDate)
      dayPageViewController.setViewControllers([newDayController], direction: direction, animated: true)
    }
  }
}
