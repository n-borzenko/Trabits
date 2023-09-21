//
//  TodayViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 04/08/2023.
//

import UIKit

final class GradientLayerView: UIView {
  override class var layerClass: AnyClass {
    return CAGradientLayer.self
  }

  private var gradientLayer: CAGradientLayer {
    return self.layer as! CAGradientLayer
  }

  init(startColor: UIColor, endColor: UIColor) {
    self.startColor = startColor
    self.endColor = endColor
    super.init(frame: .zero)

    gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private var startColor: UIColor
  private var endColor: UIColor

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
      layoutIfNeeded()
    }
  }
}

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
      [unowned self] (cell: UICollectionViewListCell, indexPath: IndexPath, itemIdentifier: TodayListDataProvider.ItemIdentifier) in
      guard case let TodayListDataProvider.ItemIdentifier.habit(objectId) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectId) as? Habit, let habit = habit else { return }

      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
      let startColor = habit.category?.color ?? .systemGray6
      let endColor = UIColor.systemGray6
      let gradientView = GradientLayerView(startColor: startColor, endColor: endColor)
      backgroundConfiguration.customView = gradientView
      backgroundConfiguration.cornerRadius = 8
      cell.backgroundConfiguration = backgroundConfiguration

      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = habit.title
      cell.contentConfiguration = contentConfiguration

      var buttonConfiguration = UIButton.Configuration.bordered()
      let isCompleted = dataProvider.completedHabitIds.contains(habit.objectID)
      buttonConfiguration.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(scale: .small))
      buttonConfiguration.baseForegroundColor = isCompleted ? .contrastColor : .backgroundColor
      buttonConfiguration.baseBackgroundColor = isCompleted ? habit.category?.color : .backgroundColor
      buttonConfiguration.background.strokeColor = .contrastColor
      buttonConfiguration.background.strokeWidth = 2
      buttonConfiguration.cornerStyle = .capsule
      buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
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
