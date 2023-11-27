//
//  StructureCategoryDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 14/11/2023.
//

import UIKit
import CoreData

class StructureCategoryDataProvider: NSObject, ObservableObject {
  enum SectionIdentifier: Hashable {
    case main
  }
  
  enum ItemIdentifier: Hashable {
    case habit(NSManagedObjectID)
  }
  
  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>
  
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var categoryFetchResultsController: NSFetchedResultsController<Category>!
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  
  var dataSource: DataSource!
  
  private let categoryObjectID: NSManagedObjectID

  @Published var isListEmpty = false
  @Published var categoryTitle: String = ""
  
  init(dataSource: DataSource, categoryObjectID: NSManagedObjectID) {
    self.dataSource = dataSource
    self.categoryObjectID = categoryObjectID
    super.init()
    configureFetchedResultsControllers()
  }
  
  func configureFetchedResultsControllers() {
    categoryFetchResultsController = NSFetchedResultsController(
      fetchRequest: Category.singleCategoryFetchRequest(objectID: categoryObjectID),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    habitsFetchResultsController = NSFetchedResultsController(
      fetchRequest: Habit.categoryOrderedHabitsFetchRequest(categoryObjectID: categoryObjectID),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    categoryFetchResultsController.delegate = self
    habitsFetchResultsController.delegate = self
    
    do {
      try categoryFetchResultsController.performFetch()
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

extension StructureCategoryDataProvider: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    var newSnapshot = Snapshot()
    defer {
      dataSource.apply(newSnapshot, animatingDifferences: false)
      isListEmpty = newSnapshot.itemIdentifiers.isEmpty
    }
    
    guard let category = categoryFetchResultsController.fetchedObjects?.first else { return }
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    
    newSnapshot.appendSections([.main])
    let habitsIdentifiers = category.getSortedHabits().map { ItemIdentifier.habit($0.objectID) }
    newSnapshot.appendItems(habitsIdentifiers, toSection: .main)
    
    if controller == categoryFetchResultsController {
      newSnapshot.reloadSections([.main])
      categoryTitle = category.title ?? ""
    } else {
      let reloadItemIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.habit($0) }
      newSnapshot.reloadItems(reloadItemIdentifiers)
    }
  }
}

extension StructureCategoryDataProvider {
  func getCategory() -> Category? {
    guard let category = categoryFetchResultsController.fetchedObjects?.first else { return nil }
    return category
  }
  
  func getHabit(habitIndex: Int) -> Habit? {
    guard let category = categoryFetchResultsController.fetchedObjects?.first else { return nil }
    let habits = category.getSortedHabits()
    guard habitIndex < habits.count else { return nil }
    return habits[habitIndex]
  }
  
  func deleteHabit(habitIndex: Int) {
    guard let category = categoryFetchResultsController.fetchedObjects?.first else { return }
    let habits = category.getSortedHabits()
    guard habitIndex < habits.count else { return }
    let habit = habits[habitIndex]
    for index in (habitIndex + 1)..<habits.count {
      habits[index].orderPriority -= 1
    }
    context.delete(habit)
    saveContextChanges()
  }
  
  func moveHabit(sourceIndex: Int, destinationIndex: Int) {
    guard let category = categoryFetchResultsController.fetchedObjects?.first else { return }
    let habits = category.getSortedHabits()
    let habit = habits[sourceIndex]
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
    
    saveContextChanges()
  }
}
