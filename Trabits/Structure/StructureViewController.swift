//
//  StructureViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 08/11/2023.
//

import UIKit
import Combine

class StructureViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  
  private var dataSource: StructureDataProvider.DataSource!
  private var dataProvider: StructureDataProvider!

  private var scopeControl = UISegmentedControl()
  private let underlinedContainerView = UnderlinedContainerView()
  
  private var defaultBarButtonItems: [UIBarButtonItem]!
  private var doneEditingBarButtonItem: UIBarButtonItem!

  private var emptyStateView: EmptyStateView!
  
  private var isNegativeCollectionScrollOffset = true {
    didSet {
      underlinedContainerView.isLineVisible = !isNegativeCollectionScrollOffset
    }
  }

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()
  
  private var cancellable: AnyCancellable?
  
  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    
    dataProvider = StructureDataProvider(dataSource: dataSource)
    scopeControl.selectedSegmentIndex = dataProvider.selectedSegment.rawValue
    cancellable = dataProvider.$isListEmpty.sink { [weak self] isEmpty in
      self?.emptyStateView.isHidden = !isEmpty
      self?.scopeControl.isEnabled = !isEmpty
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

extension StructureViewController {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.headerMode = .none
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.footerMode = .none
    
    configuration.leadingSwipeActionsConfigurationProvider = { [weak self] indexPath in
      guard let self, dataProvider.selectedSegment == .category else { return nil }
      let editCategoryAction = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, completion in
        guard let self else { completion(false); return }
        editCategory(categoryIndex: indexPath.item)
        completion(true)
      }
      editCategoryAction.backgroundColor = .neutral50
      editCategoryAction.image = UIImage(systemName: "square.and.pencil")
      return UISwipeActionsConfiguration(actions: [editCategoryAction])
    }
    
    configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
      guard let self, dataProvider.selectedSegment != .habit || indexPath.item != 0 else { return nil }
      let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
        guard let self else { completion(false); return }
        if dataProvider.selectedSegment == .category {
          dataProvider.deleteCategory(categoryIndex: indexPath.item)
        } else {
          dataProvider.deleteHabit(categoryIndex: indexPath.section, habitIndex: indexPath.item - 1)
        }
        completion(true)
      }
      deleteAction.image = UIImage(systemName: "trash")
      return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureDataSource() {
    let categoryCellRegistration = UICollectionView.CellRegistration<StructureCategoryListCell, StructureDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let StructureDataProvider.ItemIdentifier.category(objectID) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectID) as? Category, let category = category else { return }
      cell.category = category
      
      var reorderOptions = UICellAccessory.ReorderOptions()
      reorderOptions.showsVerticalSeparator = false
      cell.accessories = [.disclosureIndicator(), .delete(), .reorder(options: reorderOptions)]
    }
    
    let categoryHeaderCellRegistration = UICollectionView.CellRegistration<StructureCategoryHeaderListCell, StructureDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let StructureDataProvider.ItemIdentifier.categoryHeader(objectID) = itemIdentifier else { return }
      guard case let category = self.context.object(with: objectID) as? Category, let category = category else { return }
      cell.category = category
    }
    
    let habitCellRegistration = UICollectionView.CellRegistration<StructureHabitListCell, StructureDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let StructureDataProvider.ItemIdentifier.habit(objectID) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectID) as? Habit, let habit = habit else { return }
      cell.habit = habit
      cell.isSublevel = true
      
      var reorderOptions = UICellAccessory.ReorderOptions()
      reorderOptions.showsVerticalSeparator = false
      cell.accessories = [.delete(), .reorder(options: reorderOptions)]
    }

    dataSource = StructureDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .category(_):
        return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: itemIdentifier)
      case .categoryHeader(_):
        return collectionView.dequeueConfiguredReusableCell(using: categoryHeaderCellRegistration, for: indexPath, item: itemIdentifier)
      case .habit(_):
        return collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
      }
    }
    
    dataSource.reorderingHandlers.canReorderItem = { [weak self] itemIdentifier in
      guard let self else { return false }
      if case StructureDataProvider.ItemIdentifier.habit(_) = itemIdentifier { return true }
      return dataProvider.selectedSegment == .category
    }
    
    dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
      guard let self else { return }

      var sourceSectionIdentifier, destinationSectionIdentifier: StructureDataProvider.SectionIdentifier!
      var sourceIndex, destinationIndex: Int!
      
      transaction.sectionTransactions.forEach { sectionChange in
        sectionChange.difference.forEach { itemChange in
          if case let .insert(offset: offset, element: _, associatedWith: _) = itemChange {
            destinationSectionIdentifier = sectionChange.sectionIdentifier
            destinationIndex = offset
          }
          if case let .remove(offset: offset, element: _, associatedWith: _) = itemChange {
            sourceSectionIdentifier = sectionChange.sectionIdentifier
            sourceIndex = offset
          }
        }
      }
      
      if dataProvider.selectedSegment == .category {
        dataProvider.moveCategory(sourceIndex: sourceIndex, destinationIndex: destinationIndex)
      } else {
        dataProvider.moveHabit(sourceIndex: sourceIndex - 1, sourceSectionIdentifier: sourceSectionIdentifier, destinationIndex: destinationIndex - 1, destinationSectionIdentifier: destinationSectionIdentifier)
      }
    }
  }
}

extension StructureViewController {
  private func setupViews() {
    view.backgroundColor = .systemBackground
    
    underlinedContainerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(underlinedContainerView)
    underlinedContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    underlinedContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    underlinedContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    
    scopeControl.insertSegment(
      withTitle: StructureDataProvider.Segment.category.title,
      at: StructureDataProvider.Segment.category.rawValue,
      animated: false
    )
    scopeControl.insertSegment(
      withTitle: StructureDataProvider.Segment.habit.title,
      at: StructureDataProvider.Segment.habit.rawValue,
      animated: false
    )
    scopeControl.selectedSegmentTintColor = .neutral70
    scopeControl.setTitleTextAttributes([
      NSAttributedString.Key.foregroundColor: UIColor.inverted,
      NSAttributedString.Key.backgroundColor: UIColor.neutral70
    ], for: .selected)
    underlinedContainerView.appendSubview(scopeControl)
    scopeControl.addTarget(self, action: #selector(segmentSelectionChanged), for: .valueChanged)
    scopeControl.setContentCompressionResistancePriority(.required, for: .vertical)
    
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    collectionView.topAnchor.constraint(equalTo: underlinedContainerView.bottomAnchor).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)

    emptyStateView = EmptyStateView(message: "List is empty.\nPlease, create your first category\nand add a habit.")
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateView)
    emptyStateView.topAnchor.constraint(equalTo: underlinedContainerView.bottomAnchor).isActive = true
    emptyStateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    emptyStateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    emptyStateView.isHidden = true
    
    collectionView.delegate = self
    
    navigationItem.title = "Structure"
    
    doneEditingBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleEditMode))
    
    let startEditingBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "arrow.up.arrow.down"),
      style: .plain,
      target: self,
      action: #selector(toggleEditMode)
    )
    startEditingBarButtonItem.title = "Reorder items"
    
    let addItemBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "plus"),
      style: .plain,
      target: self,
      action: #selector(addNewItem)
    )
    addItemBarButtonItem.title = "Add new item"
    
    defaultBarButtonItems = [startEditingBarButtonItem, addItemBarButtonItem]
    navigationItem.rightBarButtonItems = defaultBarButtonItems
  }
}

extension StructureViewController {
  @objc private func segmentSelectionChanged(sender: UISegmentedControl) {
    dataProvider.selectedSegment = StructureDataProvider.Segment(rawValue: sender.selectedSegmentIndex) ?? .category
  }
  
  @objc private func toggleEditMode() {
    collectionView.isEditing.toggle()
    if collectionView.isEditing {
      navigationItem.rightBarButtonItems = nil
      navigationItem.rightBarButtonItem = doneEditingBarButtonItem
    } else {
      navigationItem.rightBarButtonItem = nil
      navigationItem.rightBarButtonItems = defaultBarButtonItems
    }
  }
  
  @objc private func addNewItem() {
    if dataProvider.selectedSegment == .habit {
      let habitEditorViewController = HabitEditorViewController(categories: dataProvider.getCategories())
      present(UINavigationController(rootViewController: habitEditorViewController), animated: true)
    } else {
      let categoryEditorViewController = CategoryEditorViewController()
      present(UINavigationController(rootViewController: categoryEditorViewController), animated: true)
    }
  }
  
  private func editCategory(categoryIndex: Int) {
    guard let category = dataProvider.getCategory(categoryIndex: categoryIndex) else { return }
    let categoryEditorViewController = CategoryEditorViewController(category: category)
    present(UINavigationController(rootViewController: categoryEditorViewController), animated: true)
  }
}

extension StructureViewController: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y >= 0 && isNegativeCollectionScrollOffset {
      isNegativeCollectionScrollOffset = false
    } else if scrollView.contentOffset.y < 0 && !isNegativeCollectionScrollOffset {
      isNegativeCollectionScrollOffset = true
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveOfItemFromOriginalIndexPath originalIndexPath: IndexPath, atCurrentIndexPath currentIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
    guard dataProvider.selectedSegment == .habit else { return proposedIndexPath }
    guard proposedIndexPath.item == 0 else { return proposedIndexPath }
    
    if currentIndexPath.section == proposedIndexPath.section {
      // moving habit down avoiding section header
      if proposedIndexPath.section == 0 {
        return IndexPath(item: 1, section: proposedIndexPath.section)
      } else {
        let count = dataSource.snapshot().numberOfItems(inSection: dataSource.snapshot().sectionIdentifiers[proposedIndexPath.section - 1])
        let offset = originalIndexPath.section == proposedIndexPath.section - 1 ? -1 : 0
        return IndexPath(item: count + offset, section: proposedIndexPath.section - 1)
      }
    } else {
      // moving habit down avoiding section header
      return IndexPath(item: 1, section: proposedIndexPath.section)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    defer { collectionView.deselectItem(at: indexPath, animated: false) }
    guard dataProvider.selectedSegment != .habit || indexPath.item != 0 else { return }
    
    if dataProvider.selectedSegment == .habit {
      guard let habit = dataProvider.getHabit(categoryIndex: indexPath.section, habitIndex: indexPath.item - 1) else { return }
      let habitEditorViewController = HabitEditorViewController(habit: habit, categories: dataProvider.getCategories())
      present(UINavigationController(rootViewController: habitEditorViewController), animated: true)
    } else {
      guard let category = dataProvider.getCategory(categoryIndex: indexPath.item) else { return }
      let categoryDetailsViewController = StructureCategoryViewController(categoryObjectID: category.objectID)
      navigationController?.pushViewController(categoryDetailsViewController, animated: true)
    }
  }
}
