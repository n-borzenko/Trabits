//
//  TodayListDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/09/2023.
//

import UIKit
import CoreData

// todo refresh date on midnight
// todo empty state view and routing to habits creation

class TodayListDataProvider: NSObject {
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
  private var dayResultFetchResultsController: NSFetchedResultsController<DayResult>!

  private(set) var completedHabitIds: Set<NSManagedObjectID> = Set()
  
  var dataSource: DataSource!

  init(dataSource: DataSource) {
    self.dataSource = dataSource
    super.init()
    configureFetchedResultsControllers()
  }

  func configureFetchedResultsControllers() {
    let categoriesRequest = Category.fetchRequest()
    categoriesRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    categoriesRequest.predicate = NSPredicate(format: "habits.@count > 0")
    categoriesFetchResultsController = NSFetchedResultsController(fetchRequest: categoriesRequest, managedObjectContext: context,
                                                              sectionNameKeyPath: nil, cacheName: nil)
    categoriesFetchResultsController.delegate = self

    let habitsRequest = Habit.fetchRequest()
    habitsRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    habitsFetchResultsController = NSFetchedResultsController(fetchRequest: habitsRequest, managedObjectContext: context,
                                                              sectionNameKeyPath: nil, cacheName: nil)
    habitsFetchResultsController.delegate = self

    let dayResultRequest = DayResult.fetchRequest()
    dayResultRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
    let interval = Calendar.current.dateInterval(of: .day, for: Date())!
    dayResultRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", interval.start as NSDate, interval.end as NSDate)
    dayResultRequest.fetchLimit = 1
    dayResultFetchResultsController = NSFetchedResultsController(fetchRequest: dayResultRequest, managedObjectContext: context,
                                                              sectionNameKeyPath: nil, cacheName: nil)
    dayResultFetchResultsController.delegate = self

    do {
      try categoriesFetchResultsController.performFetch()
      try habitsFetchResultsController.performFetch()
      try dayResultFetchResultsController.performFetch()
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

extension TodayListDataProvider: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    var newSnapshot = Snapshot()
    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else {
      // todo: show empty state
      return
    }

    newSnapshot.appendSections(categories.map { SectionIdentifier.category($0.objectID) })
    categories.forEach {
      newSnapshot.appendItems([ItemIdentifier.category($0.objectID)], toSection: SectionIdentifier.category($0.objectID))
    }

    if let habits = habitsFetchResultsController.fetchedObjects, !habits.isEmpty {
      let groupedHabits = Dictionary(grouping: habits) { $0.category?.objectID }
      for categoryId in groupedHabits.keys {
        guard let categoryId, let habitsGroup = groupedHabits[categoryId] else { continue }
        let items = habitsGroup.map { ItemIdentifier.habit($0.objectID) }
        newSnapshot.appendItems(items, toSection: SectionIdentifier.category(categoryId))
      }
    }

    if controller == categoriesFetchResultsController {
      let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { SectionIdentifier.category($0) }
      newSnapshot.reloadSections(reloadIdentifiers)
    } else if controller == habitsFetchResultsController {
      let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.habit($0) }
      newSnapshot.reloadItems(reloadIdentifiers)
    } else if let habits = dayResultFetchResultsController.fetchedObjects?.first?.completedHabits as? Set<Habit> {
      // reload habit cells and related categories with progress bar
      let updatedHabitIds = Set(habits.map { $0.objectID } )
      let reloadHabitIdentifiers = completedHabitIds.symmetricDifference(updatedHabitIds).map { ItemIdentifier.habit($0) }
      let reloadCategoryIdentifiers: [ItemIdentifier] = reloadHabitIdentifiers.compactMap { itemIdentifier in
        guard case let ItemIdentifier.habit(habitId) = itemIdentifier,
              let habit = context.object(with: habitId) as? Habit,
              let category = habit.category else { return nil }
        return ItemIdentifier.category(category.objectID)
      }
      completedHabitIds = updatedHabitIds
      let reloadIdentifiers = reloadHabitIdentifiers + Set(reloadCategoryIdentifiers)
      newSnapshot.reloadItems(reloadIdentifiers)
    }

    dataSource.apply(newSnapshot, animatingDifferences: true)
  }
}

extension TodayListDataProvider {
  func toggleCompletionFor(_ habit: Habit) {
    var dayResults = dayResultFetchResultsController.fetchedObjects?.first
    if dayResults == nil {
      dayResults = DayResult(context: context)
      dayResults?.date = Calendar.current.startOfDay(for: Date())
      dayResults?.completedHabits = Set<Habit>() as NSSet
    }

    guard let dayResults else { return }
    if let habits = dayResults.completedHabits, habits.contains(habit) {
      dayResults.removeFromCompletedHabits(habit)
    } else {
      dayResults.addToCompletedHabits(habit)
    }

    saveContextChanges()
  }
}
