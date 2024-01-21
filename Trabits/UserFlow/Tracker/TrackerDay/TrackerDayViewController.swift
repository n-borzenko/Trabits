//
//  TrackerDayViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/10/2023.
//

import UIKit
import Combine

protocol TrackerDayScrollDelegate: AnyObject {
  func scrollOffsetUpdated(offset: Double) -> Void
}

class TrackerDayViewController: UIViewController {
  private weak var trackerCoordinator: TrackerCoordinator?
  
  private let context = PersistenceController.shared.container.viewContext
  
  private var dataSource: TrackerDayDataProvider.DataSource!
  private var dataProvider: TrackerDayDataProvider!

  private var emptyStateView: EmptyStateView!

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()
  
  private var cancellable: AnyCancellable?
  
  var date: Date { dataProvider.date }
  
  weak var delegate: TrackerDayScrollDelegate?
  
  init(date: Date, trackerCoordinator: TrackerCoordinator? = nil) {
    self.trackerCoordinator = trackerCoordinator
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    
    dataProvider = TrackerDayDataProvider(dataSource: dataSource, date: date)
    cancellable = dataProvider.$isListEmpty.sink { [weak self] isEmpty in
      self?.emptyStateView.isHidden = !isEmpty
    }
    
    collectionView.dataSource = dataSource
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

extension TrackerDayViewController {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.headerMode = .none
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.footerMode = .none
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureDataSource() {
    let habitCellRegistration = UICollectionView.CellRegistration<TrackerDayHabitListCell, TrackerDayDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let TrackerDayDataProvider.ItemIdentifier.habit(objectID) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectID) as? Habit, let habit = habit else { return }
      cell.createConfiguration(
        habit: habit,
        isGrouped: dataProvider.isHabitGroupingOn,
        weekResults: dataProvider.getWeekResults(for: habit)
      ) { [weak self] in
        guard let self else { return }
        dataProvider.adjustCompletionFor(habit)
      }
    }
    
    let categoryCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, TrackerDayDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      var contentConfiguration = UIListContentConfiguration.prominentInsetGroupedHeader()
      var margins = contentConfiguration.directionalLayoutMargins
      margins.leading = 16
      margins.trailing = 16
      margins.top = margins.bottom * 2
      contentConfiguration.directionalLayoutMargins = margins
      
      if itemIdentifier == TrackerDayDataProvider.ItemIdentifier.unknownCategory {
        contentConfiguration.text = "Uncategorized"
        cell.contentConfiguration = contentConfiguration
        return
      }
      
      guard case let TrackerDayDataProvider.ItemIdentifier.category(objectID) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectID) as? Category, let category else { return }
      contentConfiguration.text = category.title ?? "Untitled"
      cell.contentConfiguration = contentConfiguration
    }
    
    dataSource = TrackerDayDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .habit(_):
        return collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
      case .category(_), .unknownCategory:
        return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: itemIdentifier)
      }
    }
  }
}

extension TrackerDayViewController: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    delegate?.scrollOffsetUpdated(offset: scrollView.contentOffset.y)
  }
}

extension TrackerDayViewController {
  private func setupViews() {
    view.addPinnedSubview(collectionView, layoutGuide: view.safeAreaLayoutGuide)
    collectionView.allowsSelection = false
    collectionView.delegate = self

    emptyStateView = EmptyStateView(
      message: "List of habits is empty. Please, create your first habit.",
      actionTitle: "Go to My Habits") { [weak self] in
      self?.trackerCoordinator?.navigateToStructureTab()
    }
    view.addPinnedSubview(emptyStateView, layoutGuide: view.safeAreaLayoutGuide)
    emptyStateView.isHidden = true
  }
}