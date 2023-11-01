//
//  HabitsListViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 09/08/2023.
//

import UIKit
import CoreData

class HabitsListViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var dataSource: HabitsListDataProvider.DataSource!
  private var dataProvider: HabitsListDataProvider!

  private var stackView = UIStackView()
  private var newCategoryButton = ActionButton()
  private var newHabitButton = ActionButton()
  private var emptyStateView: EmptyStateView!

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    dataProvider = HabitsListDataProvider(dataSource: dataSource, delegate: self)
    collectionView.dataSource = dataSource
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension HabitsListViewController {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.headerMode = .none
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.footerMode = .none

    configuration.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
      let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] action, sourceView, completionHandler in
        self?.dataProvider.deleteItem(at: indexPath)
        completionHandler(true)
      }
      deleteAction.image = UIImage(systemName: "trash")
      return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    configuration.leadingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
      guard indexPath.item == 0 else { return nil }
      let editCategoryAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] action, sourceView, completionHandler in
        self?.editCategory(at: indexPath)
        completionHandler(true)
      }
      editCategoryAction.backgroundColor = .green
      editCategoryAction.image = UIImage(systemName: "square.and.pencil")
      return UISwipeActionsConfiguration(actions: [editCategoryAction])
    }
    
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureDataSource() {
    let categoryCellRegistration = UICollectionView.CellRegistration {
      [unowned self] (cell: CategoryListCell, indexPath: IndexPath, itemIdentifier: HabitsListDataProvider.ItemIdentifier) in
      guard case let HabitsListDataProvider.ItemIdentifier.category(objectId) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectId) as? Category, let category = category else { return }
      cell.category = category
    }

    let habitCellRegistration = UICollectionView.CellRegistration {
      [unowned self] (cell: HabitListCell, indexPath: IndexPath, itemIdentifier: HabitsListDataProvider.ItemIdentifier) in
      guard case let HabitsListDataProvider.ItemIdentifier.habit(objectId) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectId) as? Habit, let habit = habit else { return }
      cell.habit = habit
    }

    dataSource = HabitsListDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .category(_):
        return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: itemIdentifier)
      case .habit(_):
        return collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
      }
    }

    dataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] itemIdentifier in
      self?.dataProvider.expandedCategories.remove(itemIdentifier)
    }

    dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] itemIdentifier in
      self?.dataProvider.expandedCategories.insert(itemIdentifier)
    }
  }

  private func setupViews() {
    view.backgroundColor = .systemBackground
    view.addPinnedSubview(collectionView, layoutGuide: view.safeAreaLayoutGuide)

    emptyStateView = EmptyStateView(
      message: "List of categories is empty.\nPlease, create your first category.",
      image: UIImage(systemName: "rectangle.stack")
    )
    view.addPinnedSubview(emptyStateView, layoutGuide: view.safeAreaLayoutGuide)
    emptyStateView.isHidden = true

    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
    stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
    stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
    
    stackView.spacing = 16
    stackView.axis = .horizontal
    let hasLargeText = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    stackView.distribution = hasLargeText ? .fillProportionally : .fillEqually

    newCategoryButton.setTitle("Add category", for: .normal)
    newCategoryButton.addTarget(self, action: #selector(addNewCategory), for: .touchUpInside)
    stackView.addArrangedSubview(newCategoryButton)

    newHabitButton.setTitle("Add habit", for: .normal)
    newHabitButton.addTarget(self, action: #selector(addNewHabit), for: .touchUpInside)
    stackView.addArrangedSubview(newHabitButton)
    newHabitButton.isHidden = true

    collectionView.delegate = self
    collectionView.dragDelegate = self
    collectionView.dropDelegate = self
    collectionView.dragInteractionEnabled = true
    collectionView.allowsSelection = true

    collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: hasLargeText ? 110 : 80, right: 0)
    navigationItem.title = "Settings"
  }

  @objc private func addNewCategory() {
    let addCategoryViewController = EditCategoryViewController(categoriesCount: dataProvider.getCategoriesCount())
    present(UINavigationController(rootViewController: addCategoryViewController), animated: true)
  }

  @objc private func addNewHabit() {
    let addHabitViewController = EditHabitViewController(categories: dataProvider.getCategories())
    present(UINavigationController(rootViewController: addHabitViewController), animated: true)
  }

  private func editCategory(at indexPath: IndexPath) {
    guard let category = dataProvider.getCategory(at: indexPath.section) else { return }
    let editCategoryViewController = EditCategoryViewController(category: category, categoriesCount: dataProvider.getCategoriesCount())
    present(UINavigationController(rootViewController: editCategoryViewController), animated: true)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    let hasLargeText = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    if hasLargeText != previousTraitCollection?.preferredContentSizeCategory.isAccessibilityCategory {
      stackView.distribution = hasLargeText ? .fillProportionally : .fillEqually
      collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: hasLargeText ? 110 : 80, right: 0)
    }
  }
}

extension HabitsListViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if indexPath.item != 0, let habit = dataProvider.getHabit(at: indexPath) {
      let editHabitViewController = EditHabitViewController(habit: habit, categories: dataProvider.getCategories())
      present(UINavigationController(rootViewController: editHabitViewController), animated: true)
    }
    collectionView.deselectItem(at: indexPath, animated: false)
  }
}

extension HabitsListViewController: HabitsListDataProviderDelegate {
  func updateEmptyState(isEmpty: Bool) {
    if isEmpty {
      newHabitButton.isHidden = true
      emptyStateView.isHidden = false
    } else {
      newHabitButton.isHidden = false
      emptyStateView.isHidden = true
    }
  }
}

// MARK: - Drag & Drop

extension HabitsListViewController: UICollectionViewDragDelegate {
  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    session.localContext = indexPath
    let itemProvider = NSItemProvider(object: "\(indexPath.section)-\(indexPath.item)" as NSString)
    let dragItem = UIDragItem(itemProvider: itemProvider)
    return [dragItem]
  }

  func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
    true
  }
}

extension HabitsListViewController: UICollectionViewDropDelegate {
  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    guard coordinator.proposal.operation == .move,
          let item = coordinator.items.first,
          let sourceIndexPath = item.sourceIndexPath else {
      return
    }

    var dropIndexPath: IndexPath

    if sourceIndexPath.item == 0 {
      // category replacement
      var destinationIndex: Int
      if let destinationIndexPath = coordinator.destinationIndexPath {
        destinationIndex = sourceIndexPath.section < destinationIndexPath.section ? destinationIndexPath.section - 1 : destinationIndexPath.section
        if destinationIndexPath.item > 0 {
          destinationIndex += 1
        }
      } else {
        destinationIndex = dataProvider.getCategoriesCount() - 1
      }
      dataProvider.moveCategory(from: sourceIndexPath.section, to: destinationIndex)
      dropIndexPath = IndexPath(item: 0, section: destinationIndex)
    } else {
      guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
      // habit replacement
      dataProvider.moveHabit(from: sourceIndexPath, to: destinationIndexPath)
      dropIndexPath = destinationIndexPath
    }
    coordinator.drop(item.dragItem, toItemAt: dropIndexPath)
  }

  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    guard collectionView == self.collectionView && collectionView.hasActiveDrag,
          let sourceIndexPath = session.localDragSession?.localContext as? IndexPath else {
      return UICollectionViewDropProposal(operation: .forbidden)
    }

    // calculate actual destination indexPath
    let location = session.location(in: collectionView)
    var actualDestinationIndexPath: IndexPath? = nil
    collectionView.performUsingPresentationValues {
      actualDestinationIndexPath = collectionView.indexPathForItem(at: location)
    }

    // category should be always the first item in a section
    if sourceIndexPath.item == 0 {
      // replacement to the end of the list is allowed (actualDestinationIndexPath == nil)
      guard let destinationIndexPath = actualDestinationIndexPath else {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
      }

      // category should be the first item in the section
      if destinationIndexPath.item == 0 {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
      }

      // category can be suggested as the last item in the section and should be placed to the next section
      let category = dataProvider.getCategory(at: destinationIndexPath.section)
      if let category = category {
        let maxItemIndex = dataProvider.expandedCategories.contains(HabitsListDataProvider.ItemIdentifier.category(category.objectID)) ? (category.habits?.count ?? 0) + 1 : 1
        if destinationIndexPath.item == maxItemIndex {
          return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
      }
    }

    if sourceIndexPath.item != 0 {
      // habit should be inside some category (section)
      guard let destinationIndexPath = destinationIndexPath else {
        return UICollectionViewDropProposal(operation: .forbidden)
      }

      // habit can be inside any section
      // if it is inserted into the category cell, habit will become the first item in the category
      return UICollectionViewDropProposal(
        operation: .move,
        intent: destinationIndexPath.item == 0 ? .insertIntoDestinationIndexPath : .insertAtDestinationIndexPath
      )
    }

    return UICollectionViewDropProposal(operation: .forbidden)
  }

  func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
    session.isRestrictedToDraggingApplication
  }
}
