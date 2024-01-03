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
    case category(String)
  }

  enum ItemIdentifier: Hashable {
    case habit(NSManagedObjectID)
    case category(NSManagedObjectID?)
  }

  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>

  private let context = PersistenceController.shared.container.viewContext
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  private var groupedHabitsFetchResultsController: NSFetchedResultsController<Habit>!
  
  private var cancellables = Set<AnyCancellable>()
  
  private(set) var isHabitGroupingOn = UserDefaults.standard.isHabitGroupingOn

  private(set) var completedHabitIds: Set<NSManagedObjectID> = Set()

  var dataSource: DataSource!
  
  let date: Date
  
  @Published var isListEmpty = false

  init(dataSource: DataSource, date: Date = Calendar.current.startOfDay(for: Date())) {
    self.date = date
    self.dataSource = dataSource
    super.init()
    
    UserDefaults.standard
      .publisher(for: \.isHabitGroupingOn)
      .sink { [weak self] in
        self?.isHabitGroupingOn = $0
        self?.configureFetchedResultsControllers()
      }
      .store(in: &cancellables)
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }

  func configureFetchedResultsControllers() {
    if isHabitGroupingOn {
      habitsFetchResultsController = NSFetchedResultsController(
        fetchRequest: Habit.orderedGroupedHabitsFetchRequest(forDate: date),
        managedObjectContext: context, sectionNameKeyPath: "categoryGroupIdentifier", cacheName: nil
      )
    } else {
      habitsFetchResultsController = NSFetchedResultsController(
        fetchRequest: Habit.orderedHabitsFetchRequest(forDate: date),
        managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
      )
    }
    
    habitsFetchResultsController.delegate = self
    
    do {
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
    if isHabitGroupingOn {
      updateGroupedHabitsSnaphot()
    } else {
      updateHabitsSnaphot()
    }
  }
  
  private func updateHabitsSnaphot() {
    var newSnapshot = Snapshot()

    defer {
      dataSource.apply(newSnapshot, animatingDifferences: true)
      isListEmpty = newSnapshot.itemIdentifiers.isEmpty
    }

    guard let habits = habitsFetchResultsController.fetchedObjects, !habits.isEmpty else { return }
    
    newSnapshot.appendSections([.main])
    let itemIdentifiers = habits.compactMap { habit in
      guard let archivedDate = habit.archivedAt else { return ItemIdentifier.habit(habit.objectID) }
      return archivedDate >= date ? ItemIdentifier.habit(habit.objectID) : nil
    }
    newSnapshot.appendItems(itemIdentifiers, toSection: .main)
  }
  
  private func updateGroupedHabitsSnaphot() {
    var newSnapshot = Snapshot()

    defer {
      dataSource.apply(newSnapshot, animatingDifferences: true)
      isListEmpty = newSnapshot.itemIdentifiers.isEmpty
    }

    guard let sections = habitsFetchResultsController.sections, !sections.isEmpty,
          let habits = habitsFetchResultsController.fetchedObjects, !habits.isEmpty else { return }

    newSnapshot.appendSections(sections.map { SectionIdentifier.category($0.name) })
    
    for sectionInfo in sections {
      guard let firstItem = sectionInfo.objects?.first as? Habit,
            let habits = sectionInfo.objects as? [Habit] else { continue }
      let sectionIdentifier = SectionIdentifier.category(sectionInfo.name)
      newSnapshot.appendItems([ItemIdentifier.category(firstItem.category?.objectID)], toSection: sectionIdentifier)
      newSnapshot.appendItems(habits.map { ItemIdentifier.habit($0.objectID) }, toSection: sectionIdentifier)
    }
  }
}
extension TrackerDayDataProvider {
  func adjustCompletionFor(_ habit: Habit) {

  }
}
