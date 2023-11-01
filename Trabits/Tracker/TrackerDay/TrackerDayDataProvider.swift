//
//  TrackerDayDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 12/10/2023.
//

import UIKit
import CoreData

class TrackerDayDataProvider: NSObject, ObservableObject {
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
  
  private let date: Date
  
  @Published var isListEmpty = false

  init(dataSource: DataSource, date: Date = Calendar.current.startOfDay(for: Date())) {
    self.date = date
    self.dataSource = dataSource
    super.init()
    configureFetchedResultsControllers()
  }

  func configureFetchedResultsControllers() {
    categoriesFetchResultsController = NSFetchedResultsController(
      fetchRequest: Category.nonEmptyCategoriesFetchRequest(),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    habitsFetchResultsController = NSFetchedResultsController(
      fetchRequest: Habit.orderedHabitsFetchRequest(),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    dayResultFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayResult.singleDayFetchRequest(date: date),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    categoriesFetchResultsController.delegate = self
    habitsFetchResultsController.delegate = self
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

extension TrackerDayDataProvider: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    var newSnapshot = Snapshot()

    defer {
      dataSource.apply(newSnapshot, animatingDifferences: true)
      isListEmpty = newSnapshot.sectionIdentifiers.isEmpty
    }

    guard let categories = categoriesFetchResultsController.fetchedObjects, !categories.isEmpty else { return }

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
      let reloadIdentifiers: [ItemIdentifier] = snapshot.reloadedItemIdentifiers.compactMap { objectId in
        guard let habit = context.object(with: objectId) as? Habit else { return nil }
        // skip updates of dayResults
        if habit.isUpdated, habit.changedValues().count == 1,
           habit.changedValues()["dayResults"] != nil {
          return nil
        }
        return ItemIdentifier.habit(objectId)
      }
      newSnapshot.reloadItems(reloadIdentifiers)
    } else if let fetchedHabits = dayResultFetchResultsController.fetchedObjects?.first?.completedHabits as? Set<Habit> {
      // reload habit cells and related categories with progress bar
      let updatedHabitIds = Set(fetchedHabits.map { $0.objectID } )
      let reconfigureHabitIdentifiers = completedHabitIds.symmetricDifference(updatedHabitIds).map { ItemIdentifier.habit($0) }
      let reconfigureCategoryIdentifiers: [ItemIdentifier] = reconfigureHabitIdentifiers.compactMap { itemIdentifier in
        guard case let ItemIdentifier.habit(habitId) = itemIdentifier,
              let habit = context.object(with: habitId) as? Habit,
              let category = habit.category else { return nil }
        return ItemIdentifier.category(category.objectID)
      }
      completedHabitIds = updatedHabitIds
      let reconfigureItems = reconfigureHabitIdentifiers + Set(reconfigureCategoryIdentifiers)
      newSnapshot.reconfigureItems(reconfigureItems)
    }
  }
}

extension TrackerDayDataProvider {
  func toggleCompletionFor(_ habit: Habit) {
    var dayResults = dayResultFetchResultsController.fetchedObjects?.first
    if dayResults == nil {
      dayResults = DayResult(context: context)
      dayResults?.date = Calendar.current.startOfDay(for: date)
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
