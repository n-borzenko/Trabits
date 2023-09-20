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

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    dataProvider = TodayListDataProvider(dataSource: dataSource)
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
      [unowned self] (cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: TodayListDataProvider.ItemIdentifier) in
      guard case let TodayListDataProvider.ItemIdentifier.category(objectId) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectId) as? Category, let category = category else { return }

      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
      backgroundConfiguration.backgroundColor = category.color ?? .systemGray6
      backgroundConfiguration.cornerRadius = 8
      cell.backgroundConfiguration = backgroundConfiguration

      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = category.title
      var count = 0
      if let habits = category.habits as? Set<Habit> {
        count = habits.filter { dataProvider.completedHabitIds.contains($0.objectID) }
          .count
      }
      contentConfiguration.secondaryText = "\(count) of \(category.habits?.count ?? 0)"
      cell.contentConfiguration = contentConfiguration
    }

    let habitCellRegistration = UICollectionView.CellRegistration {
      [unowned self] (cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: TodayListDataProvider.ItemIdentifier) in
      guard case let TodayListDataProvider.ItemIdentifier.habit(objectId) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectId) as? Habit, let habit = habit else { return }

      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
//      backgroundConfiguration.backgroundColor = habit.category?.color?.withAlphaComponent(0.7) ?? .systemGray6.withAlphaComponent(0.7)
      backgroundConfiguration.backgroundColor = .systemGray6.withAlphaComponent(0.7)
      backgroundConfiguration.cornerRadius = 8
      cell.backgroundConfiguration = backgroundConfiguration

      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = habit.title
      cell.contentConfiguration = contentConfiguration

      var buttonConfiguration = UIButton.Configuration.plain()
      let isCompleted = dataProvider.completedHabitIds.contains(habit.objectID)
      buttonConfiguration.image = UIImage(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
      buttonConfiguration.baseForegroundColor = .contrastColor
      buttonConfiguration.baseBackgroundColor = habit.category?.color?.withAlphaComponent(0.7)
      buttonConfiguration.buttonSize = .large
      let button = UIButton(configuration: buttonConfiguration, primaryAction: UIAction() { [weak self] _ in
        guard let self else { return }
        dataProvider.toggleCompletionFor(habit)
      })

      let accessoryConfiguration = UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .always))
      cell.accessories = [
        .customView(configuration: accessoryConfiguration)
      ]
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

    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .none
    navigationItem.title = dateFormatter.string(from: Date.now)
  }
}
