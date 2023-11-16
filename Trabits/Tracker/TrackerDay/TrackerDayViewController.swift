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
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  
  private var dataSource: TrackerDayDataProvider.DataSource!
  private var dataProvider: TrackerDayDataProvider!

  private var emptyStateView: EmptyStateView!

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()
  
  private var cancellable: AnyCancellable?
  
  let date: Date
  
  weak var delegate: TrackerDayScrollDelegate?
  
  init(date: Date) {
    self.date = date
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
    let categoryCellRegistration = UICollectionView.CellRegistration<TrackerDayCategoryListCell, TrackerDayDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let TrackerDayDataProvider.ItemIdentifier.category(objectId) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectId) as? Category, let category = category else { return }
      var completedHabitsCount = 0
      if let habits = category.habits as? Set<Habit> {
        completedHabitsCount = habits.filter { dataProvider.completedHabitIds.contains($0.objectID) }
          .count
      }
      cell.createConfiguration(category: category, completedHabitsCount: completedHabitsCount)
    }

    let habitCellRegistration = UICollectionView.CellRegistration<TrackerDayHabitListCell, TrackerDayDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let TrackerDayDataProvider.ItemIdentifier.habit(objectId) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectId) as? Habit, let habit = habit else { return }
      cell.createConfiguration(habit: habit, isCompleted: dataProvider.completedHabitIds.contains(habit.objectID)) { [weak self] in
        guard let self else { return }
        dataProvider.toggleCompletionFor(habit)
      }
    }

    dataSource = TrackerDayDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .habit(_):
        return collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
      case .category(_):
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
      message: "List of habits is empty.\nPlease, fill it in Settings.",
      image: UIImage(systemName: "clipboard")
    )
    view.addPinnedSubview(emptyStateView, layoutGuide: view.safeAreaLayoutGuide)
    emptyStateView.isHidden = true
  }
}
