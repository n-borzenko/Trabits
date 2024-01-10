//
//  TrackerDayDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 12/10/2023.
//

import UIKit
import CoreData
import Combine

class TrackerDayDataProvider: NSObject, ObservableObject {
  enum SectionIdentifier: Hashable {
    case main
    case category(NSManagedObjectID)
    case unknownCategory
  }

  enum ItemIdentifier: Hashable {
    case habit(NSManagedObjectID)
    case category(NSManagedObjectID)
    case unknownCategory
  }

  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>

  private let context = PersistenceController.shared.container.viewContext
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  private var categoriesFetchResultsController: NSFetchedResultsController<Category>!
  
  private var cancellables = Set<AnyCancellable>()
  
  private(set) var isHabitGroupingOn = UserDefaults.standard.isHabitGroupingOn {
    didSet {
      guard oldValue != isHabitGroupingOn else { return }
      if isHabitGroupingOn {
        updateGroupedHabitsSnaphot()
      } else {
        updateHabitsSnaphot()
      }
    }
  }

  var dataSource: DataSource!
  
  let date: Date
  
  @Published var isListEmpty = false

  init(dataSource: DataSource, date: Date = Calendar.current.startOfDay(for: Date())) {
    self.date = date
    self.dataSource = dataSource
    super.init()
    
    configureFetchedResultsControllers()
    UserDefaults.standard
      .publisher(for: \.isHabitGroupingOn)
      .sink { [weak self] in
        guard let self else { return }
        isHabitGroupingOn = $0
      }
      .store(in: &cancellables)
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }

  func configureFetchedResultsControllers() {
    categoriesFetchResultsController = NSFetchedResultsController(
      fetchRequest: Category.orderedCategoriesFetchRequest(forDate: date),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    habitsFetchResultsController = NSFetchedResultsController(
      fetchRequest: Habit.orderedHabitsFetchRequest(forDate: date),
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

extension TrackerDayDataProvider: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    if isHabitGroupingOn {
      updateGroupedHabitsSnaphot(controller, snapshot: snapshot)
    } else {
      updateHabitsSnaphot(controller, snapshot: snapshot)
    }
  }
  
  private func updateHabitsSnaphot(_ controller: NSFetchedResultsController<NSFetchRequestResult>? = nil,
                                   snapshot: NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>? = nil) {
    var newSnapshot = Snapshot()

    defer {
      dataSource.apply(newSnapshot, animatingDifferences: true)
      isListEmpty = newSnapshot.itemIdentifiers.isEmpty
    }

    guard let habits = habitsFetchResultsController.fetchedObjects, !habits.isEmpty else { return }
    
    newSnapshot.appendSections([.main])
    newSnapshot.appendItems(habits.map { ItemIdentifier.habit($0.objectID) }, toSection: .main)
    
    guard let controller, let snapshot else { return }
    if controller == categoriesFetchResultsController {
      let reloadedCategories = Set<NSManagedObjectID>(snapshot.reloadedItemIdentifiers.compactMap { objectID in
        guard let category = context.object(with: objectID) as? Category else { return nil }
        // reload in case of category properies changes
        if category.isUpdated, category.changedValues().count == 1,
           category.changedValues()["habits"] != nil {
          return nil
        }
        return objectID
      })
      let reloadIdentifiers: [ItemIdentifier] = habits.compactMap { habit in
        guard let category = habit.category, reloadedCategories.contains(category.objectID) else { return nil }
        return ItemIdentifier.habit(habit.objectID)
      }
      newSnapshot.reloadItems(reloadIdentifiers)
    }
    
    if controller == habitsFetchResultsController {
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.habit($0) }
      newSnapshot.reloadItems(reloadIdentifiers)
    }
  }
  
  private func updateGroupedHabitsSnaphot(_ controller: NSFetchedResultsController<NSFetchRequestResult>? = nil,
                                          snapshot: NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>? = nil) {
    var newSnapshot = Snapshot()

    defer {
      dataSource.apply(newSnapshot, animatingDifferences: true)
      isListEmpty = newSnapshot.itemIdentifiers.isEmpty
    }
    
    guard let habits = habitsFetchResultsController.fetchedObjects, !habits.isEmpty else { return }
    
    let categories = categoriesFetchResultsController.fetchedObjects ?? []
    categories.forEach { category in
      let sectionIdentifier = SectionIdentifier.category(category.objectID)
      newSnapshot.appendSections([sectionIdentifier])
      newSnapshot.appendItems([ItemIdentifier.category(category.objectID)], toSection: sectionIdentifier)
    }
    
    var uncategorizedHabitIdentifiers = [ItemIdentifier]()
    habits.forEach { habit in
      let itemIdentifier = ItemIdentifier.habit(habit.objectID)
      if let category = habit.category {
        newSnapshot.appendItems([itemIdentifier], toSection: SectionIdentifier.category(category.objectID))
      } else {
        uncategorizedHabitIdentifiers.append(itemIdentifier)
      }
    }
    
    if !uncategorizedHabitIdentifiers.isEmpty {
      newSnapshot.appendSections([SectionIdentifier.unknownCategory])
      newSnapshot.appendItems([ItemIdentifier.unknownCategory], toSection: SectionIdentifier.unknownCategory)
      newSnapshot.appendItems(uncategorizedHabitIdentifiers, toSection: SectionIdentifier.unknownCategory)
    }
    
    guard let controller, let snapshot else { return }
    if controller == categoriesFetchResultsController {
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { SectionIdentifier.category($0) }
      newSnapshot.reloadSections(reloadIdentifiers)
    }
    
    if controller == habitsFetchResultsController {
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.habit($0) }
      newSnapshot.reloadItems(reloadIdentifiers)
    }
  }
}
extension TrackerDayDataProvider {
  func adjustCompletionFor(_ habit: Habit) {

  }
}
