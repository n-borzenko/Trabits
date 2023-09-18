//
//  HabitsListDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit
import CoreData

class HabitsListDataProvider: NSObject {
  enum ItemIdentifier: Hashable {
    case category(NSManagedObjectID)
    case habit(NSManagedObjectID)
  }

  typealias DataSource = UICollectionViewDiffableDataSource<Int, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<Int, ItemIdentifier>

  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var fetchResultsController: NSFetchedResultsController<Category>!
  var dataSource: DataSource!

  var expandedCategories = Set<ItemIdentifier>()

  init(dataSource: DataSource) {
    self.dataSource = dataSource
    super.init()
    configureFetchedResultsController()
    NotificationCenter.default.addObserver(self, selector: #selector(handleCoreDataChanges),
                                           name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
  }

  func configureFetchedResultsController() {
    let fetchRequest = Category.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context,
                                                        sectionNameKeyPath: nil, cacheName: nil)
    fetchResultsController.delegate = self

    do {
      try fetchResultsController.performFetch()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }

  @objc private func handleCoreDataChanges(notification: NSNotification) {
    guard let userInfo = notification.userInfo,
          let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updates.isEmpty else { return }

    // update snapshot in case habits order was changed, but categories were not updated and FRC didn't trigger update
    var hasHabitChanges = false
    for update in updates {
      if let category = update as? Category, category.changedValues()["habits"] != nil {
        return
      }
      if let habit = update as? Habit, habit.changedValues()["order"] != nil {
        hasHabitChanges = true
      }
    }
    if hasHabitChanges { updateSections() }
  }
}

// MARK: - data access
extension HabitsListDataProvider {
  func getCategoriesCount() -> Int {
    fetchResultsController.fetchedObjects?.count ?? 0
  }

  func getCategories() -> [Category] {
    fetchResultsController.fetchedObjects ?? []
  }

  func getCategory(at index: Int) -> Category? {
    guard let categories = fetchResultsController.fetchedObjects, index < categories.count else { return nil }
    return categories[index]
  }

  func getHabit(at indexPath: IndexPath) -> Habit? {
    guard let categories = fetchResultsController.fetchedObjects, indexPath.section < categories.count else { return nil }
    let habits = categories[indexPath.section].habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
    guard indexPath.item <= habits.count else { return nil }
    return habits[indexPath.item - 1]
  }
}

// MARK: - data changes
extension HabitsListDataProvider {
  func moveCategory(from sourceIndex: Int, to destinationIndex: Int) {
    guard let categories = fetchResultsController.fetchedObjects, !categories.isEmpty, sourceIndex < categories.count else { return }

    let category = categories[sourceIndex]
    let destinationIndex = min(max(destinationIndex, 0), categories.count - 1)
    if sourceIndex < destinationIndex {
      for index in (sourceIndex + 1)...destinationIndex {
        categories[index].orderPriority -= 1
      }
    } else {
      for index in destinationIndex..<sourceIndex {
        categories[index].orderPriority += 1
      }
    }
    category.orderPriority = destinationIndex

    saveContextChanges()
  }

  // indexPath is 1-based (0 item is category, first habit is item 1)
  func moveHabit(from sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    guard let categories = fetchResultsController.fetchedObjects, !categories.isEmpty,
      sourceIndexPath.section < categories.count, destinationIndexPath.section < categories.count else { return }

    if sourceIndexPath.section == destinationIndexPath.section {
      let category = categories[sourceIndexPath.section]
      let habits = category.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
      guard sourceIndexPath.item <= habits.count else { return }
      let sourceIndex = sourceIndexPath.item - 1
      let habit = habits[sourceIndex]
      let expectedDestinationIndex = destinationIndexPath.item == 0 ? habits.count - 1 : destinationIndexPath.item - 1
      let destinationIndex = min(max(expectedDestinationIndex, 0), habits.count - 1)
      if sourceIndex < destinationIndex {
        for index in (sourceIndex + 1)...destinationIndex {
          habits[index].orderPriority -= 1
        }
      } else {
        for index in destinationIndex..<sourceIndex {
          habits[index].orderPriority += 1
        }
      }
      habit.orderPriority = destinationIndex
    } else {
      let sourceCategory = categories[sourceIndexPath.section]
      let sourceHabits = sourceCategory.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
      guard sourceIndexPath.item <= sourceHabits.count else { return }
      let habit = sourceHabits[sourceIndexPath.item - 1]
      for index in sourceIndexPath.item..<sourceHabits.count {
        sourceHabits[index].orderPriority -= 1
      }
      sourceCategory.removeFromHabits(habit)

      let destinationCategory = categories[destinationIndexPath.section]
      let destinationHabits = destinationCategory.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
      let expectedStartIndex = destinationIndexPath.item == 0 ? destinationHabits.count : destinationIndexPath.item - 1
      let startIndex = min(max(expectedStartIndex, 0), max(destinationHabits.count, 0))
      for index in startIndex..<destinationHabits.count {
        destinationHabits[index].orderPriority += 1
      }
      habit.orderPriority = startIndex
      destinationCategory.addToHabits(habit)
    }

    saveContextChanges()
  }

  func deleteItem(at indexPath: IndexPath) {
    guard let categories = fetchResultsController.fetchedObjects, !categories.isEmpty else { return }
    let category = categories[indexPath.section]

    if indexPath.item == 0 {
      // delete category
      expandedCategories.remove(ItemIdentifier.category(category.objectID))
      for index in (indexPath.section + 1)..<categories.count {
        categories[index].orderPriority -= 1
      }
      context.delete(category)
    } else {
      // delete habit
      let habits = category.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
      guard indexPath.item - 1 < habits.count else { return }
      let habit = habits[indexPath.item - 1]
      for index in indexPath.item..<habits.count {
        habits[index].orderPriority -= 1
      }
      context.delete(habit)
    }

    saveContextChanges()
  }
}

// MARK: - frc delegate
extension HabitsListDataProvider: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    var newSnapshot = Snapshot()
    for index in 0..<snapshot.numberOfItems {
      newSnapshot.appendSections([index])
      let itemIdentifier = snapshot.itemIdentifiers[index]
      guard let category = context.object(with: itemIdentifier) as? Category else { continue }
      newSnapshot.appendItems([ItemIdentifier.category(category.objectID)])
    }

    var reloadIdentifiers = [ItemIdentifier]()
    if #available(iOS 15.0, *) {
      reloadIdentifiers.append(contentsOf: snapshot.reloadedItemIdentifiers.map { ItemIdentifier.category($0) })
    } else {
      let reloadItems: [ItemIdentifier] = snapshot.itemIdentifiers.compactMap { objectID in
        let identifier = ItemIdentifier.category(objectID)
        guard let fetchedIndex = snapshot.indexOfItem(objectID),
              let currentIndex = dataSource.snapshot().sectionIdentifier(containingItem: identifier),
              fetchedIndex == currentIndex else { return nil }

        guard context.object(with: objectID).isUpdated else { return nil }
        return identifier
      }
      reloadIdentifiers.append(contentsOf: reloadItems)
    }
    dataSource.apply(newSnapshot)

    for index in 0..<snapshot.numberOfItems {
      let itemIdentifier = snapshot.itemIdentifiers[index]
      guard let category = context.object(with: itemIdentifier) as? Category else { continue }

      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ItemIdentifier>()
      let parentItem = ItemIdentifier.category(category.objectID)
      sectionSnapshot.append([parentItem])
      let habits = category.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
      sectionSnapshot.append(habits.map { ItemIdentifier.habit($0.objectID) }, to: parentItem)
      if expandedCategories.contains(parentItem) {
        sectionSnapshot.expand([parentItem])
      }
      dataSource.apply(sectionSnapshot, to: index, animatingDifferences: false)
    }

    var reconstructedSnapshot = dataSource.snapshot()
    reconstructedSnapshot.reloadItems(reloadIdentifiers)
    dataSource.apply(reconstructedSnapshot)
  }
}

extension HabitsListDataProvider {
  private func updateSections() {
    guard let categories = fetchResultsController.fetchedObjects, !categories.isEmpty else { return }
    for index in 0..<categories.count {
      let category = categories[index]
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ItemIdentifier>()
      let parentItem = ItemIdentifier.category(category.objectID)
      sectionSnapshot.append([parentItem])
      let habits = category.habits?.sortedArray(using: [NSSortDescriptor(key: "order", ascending: true)]) as? [Habit] ?? []
      sectionSnapshot.append(habits.map { ItemIdentifier.habit($0.objectID) }, to: parentItem)
      if expandedCategories.contains(parentItem) {
        sectionSnapshot.expand([parentItem])
      }
      dataSource.apply(sectionSnapshot, to: index, animatingDifferences: false)
    }
  }

  private func saveContextChanges() {
    do {
      try context.save()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
}
