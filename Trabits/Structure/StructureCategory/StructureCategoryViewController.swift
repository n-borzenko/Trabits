//
//  StructureCategoryViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 14/11/2023.
//

import UIKit
import Combine
import CoreData

class StructureCategoryViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  
  private var dataSource: StructureCategoryDataProvider.DataSource!
  private var dataProvider: StructureCategoryDataProvider!

  private let underlinedContainerView = UnderlinedContainerView()
  private let titleLabel = UILabel()
  
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
  
  private var cancellables: [AnyCancellable] = []
  
  init(categoryObjectID: NSManagedObjectID) {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    
    dataProvider = StructureCategoryDataProvider(dataSource: dataSource, categoryObjectID: categoryObjectID)
    cancellables.append(dataProvider.$isListEmpty.sink { [weak self] isEmpty in
      self?.emptyStateView.isHidden = !isEmpty
    })
    cancellables.append(dataProvider.$categoryTitle.sink { [weak self] title in
      self?.titleLabel.text = title
    })
    
    collectionView.dataSource = dataSource
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}

extension StructureCategoryViewController {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.headerMode = .none
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.footerMode = .none
    
    configuration.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
      let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
        guard let self else { completion(false); return }
        dataProvider.deleteHabit(habitIndex: indexPath.item)
        completion(true)
      }
      deleteAction.image = UIImage(systemName: "trash")
      return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureDataSource() {
    let habitCellRegistration = UICollectionView.CellRegistration<StructureHabitListCell, StructureCategoryDataProvider.ItemIdentifier> { [unowned self] cell, indexPath, itemIdentifier in
      guard case let StructureCategoryDataProvider.ItemIdentifier.habit(objectID) = itemIdentifier else { return }
      guard case let habit = self.context.object(with: objectID) as? Habit, let habit = habit else { return }
      cell.habit = habit
      
      var reorderOptions = UICellAccessory.ReorderOptions()
      reorderOptions.showsVerticalSeparator = false
      cell.accessories = [.delete(), .reorder(options: reorderOptions)]
    }

    dataSource = StructureCategoryDataProvider.DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
    }
    
    dataSource.reorderingHandlers.canReorderItem = { _ in true }
    
    dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
      guard let self else { return }
      var sourceIndex, destinationIndex: Int!
     
      transaction.difference.forEach { itemChange in
        if case let .insert(offset: offset, element: _, associatedWith: _) = itemChange {
          destinationIndex = offset
        }
        if case let .remove(offset: offset, element: _, associatedWith: _) = itemChange {
          sourceIndex = offset
        }
      }
      
      Task {
        await MainActor.run { [weak self] in
          guard let self else { return }
          dataProvider.moveHabit(sourceIndex: sourceIndex, destinationIndex: destinationIndex)
        }
      }
    }
  }
}

extension StructureCategoryViewController {
  private func setupViews() {
    view.backgroundColor = .systemBackground
    
    underlinedContainerView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(underlinedContainerView)
    underlinedContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    underlinedContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    underlinedContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    
    titleLabel.text = "Category title"
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    titleLabel.textAlignment = .center
    titleLabel.accessibilityTraits.insert(.header)
    underlinedContainerView.appendSubview(titleLabel)
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    collectionView.topAnchor.constraint(equalTo: underlinedContainerView.bottomAnchor).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0)

    emptyStateView = EmptyStateView(message: "List is empty.\nPlease, create your first habit in this category.")
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(emptyStateView)
    emptyStateView.topAnchor.constraint(equalTo: underlinedContainerView.bottomAnchor).isActive = true
    emptyStateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    emptyStateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    emptyStateView.isHidden = true
    
    collectionView.delegate = self
    
    doneEditingBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleEditMode))
    
    let customizeCategoryBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "square.and.pencil"),
      style: .plain,
      target: self,
      action: #selector(customizeCategory)
    )
    customizeCategoryBarButtonItem.title = "Customize category"
    
    let startEditingBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "arrow.up.arrow.down"),
      style: .plain,
      target: self,
      action: #selector(toggleEditMode)
    )
    startEditingBarButtonItem.title = "Reorder habits"
    
    let addHabitBarButtonItem = UIBarButtonItem(
      image: UIImage(systemName: "plus"),
      style: .plain,
      target: self,
      action: #selector(addNewHabit)
    )
    addHabitBarButtonItem.title = "Add new habit"
    
    defaultBarButtonItems = [startEditingBarButtonItem, customizeCategoryBarButtonItem, addHabitBarButtonItem]
    navigationItem.rightBarButtonItems = defaultBarButtonItems
  }
}

extension StructureCategoryViewController {
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
  
  @objc private func addNewHabit() {
    guard let category = dataProvider.getCategory() else { return }
    let habitEditorViewController = HabitEditorViewController(categories: [category])
    present(UINavigationController(rootViewController: habitEditorViewController), animated: true)
  }
  
  @objc private func customizeCategory() {
    guard let category = dataProvider.getCategory() else { return }
    let categoryEditorViewController = CategoryEditorViewController(category: category)
    present(UINavigationController(rootViewController: categoryEditorViewController), animated: true)
  }
}

extension StructureCategoryViewController: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y >= 0 && isNegativeCollectionScrollOffset {
      isNegativeCollectionScrollOffset = false
    } else if scrollView.contentOffset.y < 0 && !isNegativeCollectionScrollOffset {
      isNegativeCollectionScrollOffset = true
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if let habit = dataProvider.getHabit(habitIndex: indexPath.item), let category = dataProvider.getCategory() {
      let habitEditorViewController = HabitEditorViewController(habit: habit, categories: [category])
      present(UINavigationController(rootViewController: habitEditorViewController), animated: true)
    }
    collectionView.deselectItem(at: indexPath, animated: false)
  }
}

