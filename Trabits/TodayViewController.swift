//
//  TodayViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 04/08/2023.
//

import UIKit

class TodayViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var dataSource: TodayListDataProvider.DataSource!
  private var dataProvider: TodayListDataProvider!

  private var emptyStateView: EmptyStateView!

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  private var dateFormatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }()

  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    dataProvider = TodayListDataProvider(dataSource: dataSource, delegate: self)
    collectionView.dataSource = dataSource
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension TodayViewController {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.headerMode = .none
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.footerMode = .none
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureDataSource() {
    let categoryCellRegistration = UICollectionView.CellRegistration {
      [unowned self] (cell: TodayCategoryListCell, indexPath: IndexPath, itemIdentifier: TodayListDataProvider.ItemIdentifier) in
      guard case let TodayListDataProvider.ItemIdentifier.category(objectId) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectId) as? Category, let category = category else { return }

      var completedHabitsCount = 0
      if let habits = category.habits as? Set<Habit> {
        completedHabitsCount = habits.filter { dataProvider.completedHabitIds.contains($0.objectID) }
          .count
      }
      cell.fill(category: category, completedHabitsCount: completedHabitsCount)
    }

    let habitCellRegistration = UICollectionView.CellRegistration {
      [unowned self] (cell: TodayHabitListCell, indexPath: IndexPath, itemIdentifier: TodayListDataProvider.ItemIdentifier) in
      guard case let TodayListDataProvider.ItemIdentifier.habit(objectId) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectId) as? Habit, let habit = habit else { return }

      cell.fill(habit: habit, isCompleted: dataProvider.completedHabitIds.contains(habit.objectID), completionAction: UIAction() { [weak self] _ in
        guard let self else { return }
        dataProvider.toggleCompletionFor(habit)
      })
    }

    dataSource = TodayListDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .habit(_):
        return collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
      case .category(_):
        return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: itemIdentifier)
      }
    }
  }
}

extension TodayViewController {
  private func setupViews() {
    view.backgroundColor = .backgroundColor
    view.addPinnedSubview(collectionView, layoutGuide: view.safeAreaLayoutGuide)
    collectionView.allowsSelection = false

    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Before", style: .plain, target: self, action: #selector(showDayBefore))
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "After", style: .plain, target: self, action: #selector(showDayAfter))

    emptyStateView = EmptyStateView(
      message: "List of habits is empty.\nPlease, fill it in Settings.",
      image: UIImage(systemName: "clipboard")
    )
    view.addPinnedSubview(emptyStateView, layoutGuide: view.safeAreaLayoutGuide)
    emptyStateView.isHidden = true
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    navigationItem.title = dateFormatter.string(from: dataProvider.date)
  }

  @objc private func showDayBefore() {
    dataProvider.date = Calendar.current.date(byAdding: .day, value: -1, to: dataProvider.date) ?? Date()
    navigationItem.title = dateFormatter.string(from: dataProvider.date)
  }

  @objc private func showDayAfter() {
    dataProvider.date = Calendar.current.date(byAdding: .day, value: 1, to: dataProvider.date) ?? Date()
    navigationItem.title = dateFormatter.string(from: dataProvider.date)
  }
}

extension TodayViewController: TodayListDataProviderDelegate {
  func updateEmptyState(isEmpty: Bool) {
    emptyStateView.isHidden = !isEmpty
  }
}
