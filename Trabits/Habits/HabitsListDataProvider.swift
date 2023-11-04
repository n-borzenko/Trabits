//
//  HabitsListDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit
import CoreData

class HabitsListDataProvider: NSObject, ObservableObject {
  enum SectionIdentifier: Hashable {
    case category(NSManagedObjectID)
  }
  
  enum ItemIdentifier: Hashable {
    case category(NSManagedObjectID)
    case habit(NSManagedObjectID)
  }

  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>

  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var categoriesFetchResultsController: NSFetchedResultsController<Category>!
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  var dataSource: DataSource!

  var expandedCategories = Set<ItemIdentifier>()

  @Published var isListEmpty = false

  init(dataSource: DataSource) {
    self.dataSource = dataSource
    super.init()
    configureFetchedResultsControllers()
  }

  func configureFetchedResultsControllers() {
    categoriesFetchResultsController = NSFetchedResultsController(
      fetchRequest: Category.orderedCategoriesFetchRequest(),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    habitsFetchResultsController = NSFetchedResultsController(
      fetchRequest: Habit.orderedHabitsFetchRequest(),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    categoriesFetchResultsController.delegate = self
    habitsFetchResultsController.delegate = self

    do {
      try categoriesFetchResultsController.performFetch()
      try habitsFetchResultsController.performFetch()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
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

// MARK: - data access
extension HabitsListDataProvider {
  func getCategoriesCount() -> Int {
    categoriesFetchResultsController.fetchedObjects?.count ?? 0
  }

  func getCategories() -> [Category] {
    categoriesFetchResultsController.fetchedObjects ?? []
  }

  func getCategory(at index: Int) -> Category? {
    guard let categories = categoriesFetchResultsController.fetchedObjects, index < categories.count else { return nil }
    return categories[index]
  }

  func getHabit(at indexPath: IndexPath) -> Habit? {
    guard let categories = categoriesFetchResultsController.fetchedObjects, indexPath.section < categories.count else { return nil }
    let habits = categories[indexPath.section].getSortedHabits()
    guard indexPath.item <= habits.count else { return nil }
    return habits[indexPath.item - 1]
  }
}

// MARK: - data changes
extension HabitsListDataProvider {
  func moveCategory(from sourceIndex: Int, to destinationIndex: Int) {
    print("category from \(sourceIndex) to \(destinationIndex)")
    guard let categories = categoriesFetchResultsController.fetchedObjects,
          !categories.isEmpty, sourceIndex < categories.count else { return }
   
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
    print("habit from \(sourceIndexPath) to \(destinationIndexPath)")
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty,
      sourceIndexPath.section < categories.count, destinationIndexPath.section < categories.count else { return }


    if sourceIndexPath.section == destinationIndexPath.section {
      let category = categories[sourceIndexPath.section]
      let habits = category.getSortedHabits()
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
      let sourceHabits = sourceCategory.getSortedHabits()
      guard sourceIndexPath.item <= sourceHabits.count else { return }
      let habit = sourceHabits[sourceIndexPath.item - 1]
      for index in sourceIndexPath.item..<sourceHabits.count {
        sourceHabits[index].orderPriority -= 1
      }
      sourceCategory.removeFromHabits(habit)

      let destinationCategory = categories[destinationIndexPath.section]
      let destinationHabits = destinationCategory.getSortedHabits()
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
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }
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
      let habits = category.getSortedHabits()
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
    print("UPADTAEEEEEEEEEE!!!!!")
    if controller == habitsFetchResultsController {
      let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
      var reloadIdentifiers: [ItemIdentifier] = []
      var hasOrderChangesInsideSingleCategory = false
      
      for objectID in snapshot.reloadedItemIdentifiers {
        guard let habit = context.object(with: objectID) as? Habit else { continue }
        // skip updates of dayResults
        if habit.isUpdated, habit.changedValues().count == 1, habit.changedValues()["dayResults"] != nil { continue }
        // skip updates for habits in collapsed categories
        if let categoryObjectID = habit.category?.objectID, !expandedCategories.contains(ItemIdentifier.category(categoryObjectID)) { continue }
        // habits reorder inside the same category cannot be handled by categoriesFetchResultsController and requires snapshot regeneration
        if habit.isUpdated, habit.changedValues().count == 1, habit.changedValues()["order"] != nil { hasOrderChangesInsideSingleCategory = true }
        reloadIdentifiers.append(ItemIdentifier.habit(objectID))
      }
      
      guard !reloadIdentifiers.isEmpty else { return }
      guard hasOrderChangesInsideSingleCategory else {
        print("------habits reload", reloadIdentifiers)
        var newSnapshot = dataSource.snapshot()
        newSnapshot.reloadItems(reloadIdentifiers)
        dataSource.apply(newSnapshot, animatingDifferences: false)
        return
      }
    }
    
    var newSnapshot = Snapshot()
    defer { isListEmpty = newSnapshot.sectionIdentifiers.isEmpty }
    
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else {
      dataSource.apply(newSnapshot, animatingDifferences: false)
      return
    }
    
    newSnapshot.appendSections(categories.map { SectionIdentifier.category($0.objectID) })
    categories.forEach {
      newSnapshot.appendItems([ItemIdentifier.category($0.objectID)], toSection: SectionIdentifier.category($0.objectID))
    }
    
    if controller == categoriesFetchResultsController {
      let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.category($0) }
      print("------categories reload", reloadIdentifiers)
      newSnapshot.reloadItems(reloadIdentifiers)
    }
    dataSource.apply(newSnapshot, animatingDifferences: false)

    for category in categories {
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ItemIdentifier>()
      let parentItem = ItemIdentifier.category(category.objectID)
      sectionSnapshot.append([parentItem])
      sectionSnapshot.append(category.getSortedHabits().map { ItemIdentifier.habit($0.objectID) }, to: parentItem)
      if expandedCategories.contains(parentItem) {
        sectionSnapshot.expand([parentItem])
      }
      dataSource.apply(sectionSnapshot, to: SectionIdentifier.category(category.objectID), animatingDifferences: false)
    }
  }
}
