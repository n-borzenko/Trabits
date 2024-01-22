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
    let layout = UICollectionViewCompositionalLayout { [unowned self] sectionIndex, layoutEnvironment in
      var configuration: UICollectionLayoutListConfiguration
      if !self.dataProvider.isHabitGroupingOn {
        configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.headerMode = .none
      } else {
        configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        configuration.headerMode = .supplementary
      }
      configuration.showsSeparators = false
      configuration.backgroundColor = .clear
      configuration.footerMode = .none
      return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
    }
    return layout
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
    
    dataSource = TrackerDayDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
    }
    
    let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
      elementKind: UICollectionView.elementKindSectionHeader
    ) { [unowned self] headerView, elementKind, indexPath in
      var contentConfiguration = UIListContentConfiguration.prominentInsetGroupedHeader()
      var margins = contentConfiguration.directionalLayoutMargins
      margins.leading = 20
      margins.trailing = 20
      contentConfiguration.directionalLayoutMargins = margins
      
      let itemIdentifier = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
      if itemIdentifier == TrackerDayDataProvider.SectionIdentifier.unknownCategory {
        contentConfiguration.text = "Uncategorized"
        headerView.contentConfiguration = contentConfiguration
        return
      }
      
      guard case let TrackerDayDataProvider.SectionIdentifier.category(objectID) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectID) as? Category, let category else { return }
      contentConfiguration.text = category.title ?? "Untitled"
      headerView.contentConfiguration = contentConfiguration
    }
    
    dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
      collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
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
