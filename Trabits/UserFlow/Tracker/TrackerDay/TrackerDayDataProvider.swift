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
  }

  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>

  private let context = PersistenceController.shared.container.viewContext
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  private var categoriesFetchResultsController: NSFetchedResultsController<Category>!
  private var dayResultsFetchResultsController: NSFetchedResultsController<DayResult>!
  private var dayTargetsFetchResultsController: NSFetchedResultsController<DayTarget>!
  private var weekGoalsFetchResultsController: NSFetchedResultsController<WeekGoal>!

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
    dayResultsFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayResult.weekResultsFetchRequest(forDate: date),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    dayTargetsFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayTarget.targetsUntilNextWeekFetchRequest(forDate: date),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    weekGoalsFetchResultsController = NSFetchedResultsController(
      fetchRequest: WeekGoal.goalsUntilNextWeekFetchRequest(forDate: date),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    categoriesFetchResultsController.delegate = self
    habitsFetchResultsController.delegate = self
    dayResultsFetchResultsController.delegate = self
    dayTargetsFetchResultsController.delegate = self
    weekGoalsFetchResultsController.delegate = self

    do {
      try categoriesFetchResultsController.performFetch()
      try habitsFetchResultsController.performFetch()
      try dayResultsFetchResultsController.performFetch()
      try dayTargetsFetchResultsController.performFetch()
      try weekGoalsFetchResultsController.performFetch()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }

  func getWeekResults(for habit: Habit) -> HabitWeekResults {
    var results = HabitWeekResults()

    guard let dayResults = dayResultsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let dayTargets = dayTargetsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let weekGoals = weekGoalsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let weekInterval = Calendar.current.weekInterval(for: date) else { return results }

    let weekCompletions = getWeekCompletions(dayResults: dayResults)
    results.completionCount = weekCompletions.completionCount

    var currentDate = weekInterval.end
    var targetsIndex = dayTargets.count - 1
    while currentDate > weekInterval.start && targetsIndex >= 0 {
      guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
      currentDate = newDate

      while let targetDate = dayTargets[targetsIndex].applicableFrom, targetDate > currentDate {
        targetsIndex -= 1
      }

      if currentDate == date {
        results.completionTarget = Int(dayTargets[targetsIndex].count)
      }

      let index = Calendar.current.viewWeekdayIndex(currentDate)
      if weekCompletions.completions[index] > 0 {
        results.progress[index] = weekCompletions.completions[index] >= dayTargets[targetsIndex].count ?
          .completed :
          .partial
      }
    }

    if !weekGoals.isEmpty {
      var goalsIndex = weekGoals.count - 1
      while let goalDate = weekGoals[goalsIndex].applicableFrom, goalDate > date {
        goalsIndex -= 1
      }
      results.weekGoal = Int(weekGoals[goalsIndex].count)
    }
    results.weekResult = results.progress.filter({ $0 == .completed }).count
    return results
  }

  private func getWeekCompletions(dayResults: [DayResult]) -> (completions: [Int], completionCount: Int) {
    var completions = Array(repeating: 0, count: 7)
    var completionCount = 0

    for dayResult in dayResults {
      guard dayResult.completionCount > 0, let resultDate = dayResult.date else { continue }
      let index = Calendar.current.viewWeekdayIndex(resultDate)
      completions[index] = Int(dayResult.completionCount)
      if dayResult.date == date {
        completionCount = Int(dayResult.completionCount)
      }
    }
    return (completions, completionCount)
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
  func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
  ) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
    if isHabitGroupingOn {
      updateGroupedHabitsSnaphot(controller, snapshot: snapshot)
    } else {
      updateHabitsSnaphot(controller, snapshot: snapshot)
    }
  }

  private func updateHabitsSnaphot(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>? = nil,
    snapshot: NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>? = nil
  ) {
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
        // reload if category properties were changed
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

    newSnapshot.reconfigureItems(getReconfiguredIdentifiers(controller, snapshot: snapshot))
  }

  private func updateGroupedHabitsSnaphot(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>? = nil,
    snapshot: NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>? = nil
  ) {
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
      newSnapshot.appendItems(uncategorizedHabitIdentifiers, toSection: SectionIdentifier.unknownCategory)
    }

    guard let controller, let snapshot else { return }
    if controller == categoriesFetchResultsController {
      let reloadIdentifiers = snapshot.reloadedItemIdentifiers.map { SectionIdentifier.category($0) }
      newSnapshot.reloadSections(reloadIdentifiers)
    }

    newSnapshot.reconfigureItems(getReconfiguredIdentifiers(controller, snapshot: snapshot))
  }

  private func getReconfiguredIdentifiers(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    snapshot: NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
  ) -> [ItemIdentifier] {
    if controller == habitsFetchResultsController {
      let reconfiguredIdentifiers = snapshot.reloadedItemIdentifiers.map { ItemIdentifier.habit($0) }
      return reconfiguredIdentifiers
    }

    if controller == dayResultsFetchResultsController {
      let insertedIdentifiers: [ItemIdentifier] = dayResultsFetchResultsController.fetchedObjects?
        .compactMap { dayResult in
          guard dayResult.isInserted, let habitObjectID = dayResult.habit?.objectID else { return nil }
          return ItemIdentifier.habit(habitObjectID)
        } ?? []
      let reloadedIdentifiers: [ItemIdentifier] = snapshot.reloadedItemIdentifiers.compactMap { objectID in
        guard let dayResult = context.object(with: objectID) as? DayResult,
              let habitObjectID = dayResult.habit?.objectID else { return nil }
        return ItemIdentifier.habit(habitObjectID)
      }
      return insertedIdentifiers + reloadedIdentifiers
    }

    if controller == weekGoalsFetchResultsController {
      let insertedIdentifiers: [ItemIdentifier] = weekGoalsFetchResultsController.fetchedObjects?
        .compactMap { weekGoal in
          guard weekGoal.isInserted, let habitObjectID = weekGoal.habit?.objectID else { return nil }
          return ItemIdentifier.habit(habitObjectID)
        } ?? []
      let reloadedIdentifiers: [ItemIdentifier] = snapshot.reloadedItemIdentifiers.compactMap { objectID in
        guard let weekGoal = context.object(with: objectID) as? WeekGoal,
              let habitObjectID = weekGoal.habit?.objectID else { return nil }
        return ItemIdentifier.habit(habitObjectID)
      }
      return insertedIdentifiers + reloadedIdentifiers
    }

    if controller == dayTargetsFetchResultsController {
      let insertedIdentifiers: [ItemIdentifier] = dayTargetsFetchResultsController.fetchedObjects?
        .compactMap { dayTarget in
          guard dayTarget.isInserted, let habitObjectID = dayTarget.habit?.objectID else { return nil }
          return ItemIdentifier.habit(habitObjectID)
        } ?? []
      let reloadedIdentifiers: [ItemIdentifier] = snapshot.reloadedItemIdentifiers.compactMap { objectID in
        guard let dayTarget = context.object(with: objectID) as? DayTarget,
              let habitObjectID = dayTarget.habit?.objectID else { return nil }
        return ItemIdentifier.habit(habitObjectID)
      }
      return insertedIdentifiers + reloadedIdentifiers
    }

    return []
  }
}

extension TrackerDayDataProvider {
  func adjustCompletionFor(_ habit: Habit) {
    var dayTarget = 1
    if let dayTargets = dayTargetsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
       !dayTargets.isEmpty {
      var targetsIndex = dayTargets.count - 1
      while targetsIndex >= 0, let targetDate = dayTargets[targetsIndex].applicableFrom, targetDate > date {
        targetsIndex -= 1
      }
      dayTarget = Int(dayTargets[targetsIndex].count)
    }

    if let dayResult = dayResultsFetchResultsController.fetchedObjects?.first(
      where: { $0.habit == habit && $0.date == date }
    ) {
      if dayResult.completionCount < dayTarget {
        dayResult.completionCount += 1
      } else {
        context.delete(dayResult)
      }
    } else {
      let dayResult = DayResult(context: context)
      dayResult.date = date
      dayResult.completionCount = 1
      dayResult.habit = habit

      do {
        try context.obtainPermanentIDs(for: [dayResult])
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }

    saveContextChanges()
  }
}
