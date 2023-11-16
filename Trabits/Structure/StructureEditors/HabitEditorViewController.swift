//
//  HabitEditorViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 15/11/2023.
//

import UIKit
import CoreData

struct HabitDraft {
  var title: String?
  var category: Category?
}

class HabitEditorViewController: UIViewController {
  private enum Section: Int {
    case title
    case category
  }

  private enum Item: Hashable {
    case header(String)
    case title
    case category
  }

  private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var dataSource: DataSource!
  private var saveBarButton: UIBarButtonItem!

  private var habit: Habit?
  private var habitDraft = HabitDraft()
  private var categories: [Category]
  private var isValid = false

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  init(habit: Habit? = nil, categories: [Category]) {
    self.habit = habit
    self.categories = categories
    super.init(nibName: nil, bundle: nil)

    configureHabitDraft()
    setupViews()
    configureDataSource()
    applySnapshot()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension HabitEditorViewController {
  private func validate() {
    if let title = habitDraft.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && habitDraft.category != nil {
      isValid = true
    } else {
      isValid = false
    }
    saveBarButton.isEnabled = isValid
    applySnapshot()
  }

  @objc private func cancel() {
    dismiss(animated: true)
  }

  @objc private func saveHabit() {
    guard isValid else { return }

    if let habit = habit {
      habit.title = habitDraft.title?.trimmingCharacters(in: .whitespacesAndNewlines)
      if habit.category != habitDraft.category {
        let sourceHabits = habit.category?.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
        for i in habit.orderPriority..<sourceHabits.count {
          sourceHabits[i].orderPriority -= 1
        }
        let destinationHabitsCount = habitDraft.category?.habits?.count ?? 0
        habit.category = habitDraft.category
        habit.orderPriority = destinationHabitsCount
      }
    } else {
      let habit = Habit(context: context)
      habit.title = habitDraft.title?.trimmingCharacters(in: .whitespacesAndNewlines)
      habit.orderPriority = habitDraft.category?.habits?.count ?? 0
      habit.category = habitDraft.category
      habit.dayResults = Set<DayResult>() as NSSet
      do {
        try context.obtainPermanentIDs(for: [habit])
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }

    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
    dismiss(animated: true)
  }

  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    configuration.headerMode = .firstItemInSection
    configuration.showsSeparators = false
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureHabitDraft() {
    habitDraft.category = categories.first
    guard let habit = habit else { return }
    habitDraft.title = habit.title
    habitDraft.category = habit.category
  }

  private func configureDataSource() {
    let textCellRegistration = UICollectionView.CellRegistration<TextFieldListCell, Item> { [unowned self] cell, indexPath, item in
      cell.textField.text = habitDraft.title
      cell.delegate = self
    }

    let categoryPickerCellRegistration = UICollectionView.CellRegistration<CategoryPickerListCell, Item> { [unowned self] cell, indexPath, item in
      cell.delegate = self
      let index = habitDraft.category != nil ? categories.firstIndex(of: habitDraft.category!) as Int? : nil
      cell.fill(with: categories, selectedIndex: index)
    }

    let headerCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
      guard case let .header(text) = item else { return }
      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = text
      cell.contentConfiguration = contentConfiguration
    }

    dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
      switch item {
      case .header(_):
        return collectionView.dequeueConfiguredReusableCell(using: headerCellRegistration, for: indexPath, item: item)
      case .title:
        return collectionView.dequeueConfiguredReusableCell(using: textCellRegistration, for: indexPath, item: item)
      case .category:
        return collectionView.dequeueConfiguredReusableCell(using: categoryPickerCellRegistration, for: indexPath, item: item)
      }
    }
    collectionView.dataSource = dataSource
  }

  private func applySnapshot() {
    var snapshot = Snapshot()
    snapshot.appendSections([.title, .category])
    snapshot.appendItems([.header("Title"), .title], toSection: .title)
    snapshot.appendItems([.header("Category"), .category], toSection: .category)
    dataSource.apply(snapshot)
  }

  private func setupViews() {
    view.addPinnedSubview(collectionView)
    collectionView.allowsSelection = false
    collectionView.keyboardDismissMode = .interactiveWithAccessory

    saveBarButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveHabit))
    saveBarButton.isEnabled = false
    navigationItem.rightBarButtonItem = saveBarButton
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    navigationItem.title = habit != nil ? "Edit habit" : "New habit"
  }
}

extension HabitEditorViewController: TextFieldListCellDelegate {
  func textValueChanged(_ text: String?) {
    habitDraft.title = text
    validate()
  }
}

extension HabitEditorViewController: CategoryPickerListCellDelegate {
  func selectedCategoryIndexChanged(_ index: Int?) {
    if let index = index, index < categories.count {
      habitDraft.category = categories[index]
    } else {
      habitDraft.category = nil
    }
    validate()
  }
}
