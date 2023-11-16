//
//  StructureDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 08/11/2023.
//

import UIKit
import CoreData

class StructureDataProvider: NSObject, ObservableObject {
  enum Segment: Int {
    case category
    case habit
    
    var title: String {
      switch self {
      case .category: return "Categories"
      case .habit: return "All Habits"
      }
    }
  }
  
  enum SectionIdentifier: Hashable {
    case main
    case category(NSManagedObjectID)
  }
  
  enum ItemIdentifier: Hashable {
    case category(NSManagedObjectID)
    case categoryHeader(NSManagedObjectID)
    case habit(NSManagedObjectID)
  }
  
  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>
  
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext
  private var categoriesFetchResultsController: NSFetchedResultsController<Category>!
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  
  var dataSource: DataSource!
  
  var selectedSegment = Segment.category {
    didSet {
      updateSnapshot()
    }
  }
  
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
  
  private func updateSnapshot() {
    var newSnapshot = Snapshot()
    defer {
      dataSource.apply(newSnapshot, animatingDifferences: false)
      isListEmpty = newSnapshot.itemIdentifiers.isEmpty
    }
    
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }
    
    if selectedSegment == .category {
      newSnapshot.appendSections([SectionIdentifier.main])
      newSnapshot.appendItems(categories.map { ItemIdentifier.category($0.objectID) })
    } else {
      newSnapshot.appendSections(categories.map { SectionIdentifier.category($0.objectID) })
      for category in categories {
        let habitsIdentifiers = category.getSortedHabits().map { ItemIdentifier.habit($0.objectID) }
        let sectionIdentifier = SectionIdentifier.category(category.objectID)
        newSnapshot.appendItems([ItemIdentifier.categoryHeader(category.objectID)], toSection: sectionIdentifier)
        newSnapshot.appendItems(habitsIdentifiers, toSection: sectionIdentifier)
      }
    }
  }
}

extension StructureDataProvider: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

    Task {
      await MainActor.run { [weak self] in
        guard let self else { return }
        // skip updates from habits frc in case habits are not currently visible
        guard selectedSegment != .category || controller != habitsFetchResultsController else { return }
        var newSnapshot = Snapshot()
        defer {
          dataSource.apply(newSnapshot, animatingDifferences: false)
          isListEmpty = newSnapshot.itemIdentifiers.isEmpty
        }
        
        guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }
        
        if selectedSegment == .category {
          newSnapshot.appendSections([.main])
          newSnapshot.appendItems(categories.map { ItemIdentifier.category($0.objectID) })
          
          let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.category($0) }
          newSnapshot.reloadItems(reloadIdentifiers)
        } else {
          newSnapshot.appendSections(categories.map { SectionIdentifier.category($0.objectID) })
          for category in categories {
            let habitsIdentifiers = category.getSortedHabits().map { ItemIdentifier.habit($0.objectID) }
            let sectionIdentifier = SectionIdentifier.category(category.objectID)
            newSnapshot.appendItems([ItemIdentifier.categoryHeader(category.objectID)], toSection: sectionIdentifier)
            newSnapshot.appendItems(habitsIdentifiers, toSection: sectionIdentifier)
          }
          
          if controller == categoriesFetchResultsController {
            let reloadSectionIdentifiers = snapshot.reloadedItemIdentifiers.map { SectionIdentifier.category($0) }
            newSnapshot.reloadSections(reloadSectionIdentifiers)
          } else {
            let reloadItemIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.habit($0) }
            newSnapshot.reloadItems(reloadItemIdentifiers)
          }
        }
      }
    }
  }
}

extension StructureDataProvider {
  func getCategories() -> [Category] {
    categoriesFetchResultsController.fetchedObjects ?? []
  }
  
  func getCategory(categoryIndex: Int) -> Category? {
    guard let categories = categoriesFetchResultsController.fetchedObjects,
          categoryIndex < categories.count else { return nil }
    return categories[categoryIndex]
  }

  func getHabit(categoryIndex: Int, habitIndex: Int) -> Habit? {
    guard let categories = categoriesFetchResultsController.fetchedObjects,
          categoryIndex < categories.count else { return nil }
    let habits = categories[categoryIndex].getSortedHabits()
    guard habitIndex < habits.count else { return nil }
    return habits[habitIndex]
  }
  
  func deleteHabit(categoryIndex: Int, habitIndex: Int) {
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }
    let category = categories[categoryIndex]
    let habits = category.getSortedHabits()
    guard habitIndex < habits.count else { return }
    let habit = habits[habitIndex]
    for index in (habitIndex + 1)..<habits.count {
      habits[index].orderPriority -= 1
    }
    context.delete(habit)
    saveContextChanges()
  }
  
  func deleteCategory(categoryIndex: Int) {
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }
    let category = categories[categoryIndex]
    for index in (categoryIndex + 1)..<categories.count {
      categories[index].orderPriority -= 1
    }
    context.delete(category)
    saveContextChanges()
  }
  
  // zero-based offset
  func moveHabit(sourceIndex: Int, sourceSectionIdentifier: SectionIdentifier, destinationIndex: Int, destinationSectionIdentifier: SectionIdentifier) {
    if sourceSectionIdentifier == destinationSectionIdentifier {
      // reorder habits inside the same category
      guard case let StructureDataProvider.SectionIdentifier.category(objectID) = sourceSectionIdentifier else { return }
      guard case let category = self.context.object(with: objectID) as? Category, let category else { return }
      
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
    } else {
      // move habit from one category to another
      guard case let StructureDataProvider.SectionIdentifier.category(objectID) = sourceSectionIdentifier else { return }
      guard case let sourceCategory = self.context.object(with: objectID) as? Category, let sourceCategory else { return }
      let sourceHabits = sourceCategory.getSortedHabits()
      let habit = sourceHabits[sourceIndex]
      for index in (sourceIndex + 1)..<sourceHabits.count {
        sourceHabits[index].orderPriority -= 1
      }
      sourceCategory.removeFromHabits(habit)
      
      guard case let StructureDataProvider.SectionIdentifier.category(objectID) = destinationSectionIdentifier else { return }
      guard case let destinationCategory = self.context.object(with: objectID) as? Category, let destinationCategory else { return }
      let destinationHabits = destinationCategory.getSortedHabits()
      for index in destinationIndex..<destinationHabits.count {
        destinationHabits[index].orderPriority += 1
      }
      habit.orderPriority = destinationIndex
      destinationCategory.addToHabits(habit)
    }
    
    saveContextChanges()
  }
  
  func moveCategory(sourceIndex: Int, destinationIndex: Int) {
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }
    
    let category = categories[sourceIndex]
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
}
