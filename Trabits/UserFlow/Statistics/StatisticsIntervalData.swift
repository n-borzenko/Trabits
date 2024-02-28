//
//  StatisticsIntervalData.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/02/2024.
//

import Foundation
import CoreData

enum StatisticsDayProgress {
  case none(target: Int)
  case partial(completed: Int, target: Int)
  case completed(completed: Int, target: Int)
  
  var message: String {
    switch self {
    case .none(target: _): return "not completed"
    case .partial(completed: _, target: _): return "partially completed"
    case .completed(completed: _, target: _): return "fully completed"
    }
  }
}

protocol StatisticsResults {
  var dayTarget: DayTarget? { get set }
  var weekGoal: WeekGoal? { get set }
  var progress: [StatisticsDayProgress] { get set }
}

class StatisticsIntervalData: NSObject, ObservableObject {
  internal let interval: DateInterval
  
  private let context: NSManagedObjectContext
  
  internal var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  internal var categoriesFetchResultsController: NSFetchedResultsController<Category>!
  internal var dayResultsFetchResultsController: NSFetchedResultsController<DayResult>!
  internal var dayTargetsFetchResultsController: NSFetchedResultsController<DayTarget>!
  internal var weekGoalsFetchResultsController: NSFetchedResultsController<WeekGoal>!
  
  enum CategoryWrapper: Identifiable, Hashable {
    case category(category: Category)
    case uncategorized
    
    var id: Self {
      return self
    }
  }
  
  struct HabitWithResults<Results: StatisticsResults>: Identifiable {
    var habit: Habit
    var results: Results
    
    var id: ObjectIdentifier { habit.id }
  }
  
  @Published internal var categories: [CategoryWrapper] = []
  
  init(interval: DateInterval, context: NSManagedObjectContext) {
    self.interval = interval
    self.context = context
    super.init()
    configureFetchedResultsControllers()
  }
  
  func configureFetchedResultsControllers() {
    categoriesFetchResultsController = NSFetchedResultsController(
      fetchRequest: Category.orderedCategoriesFetchRequest(forDate: interval.start),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    habitsFetchResultsController = NSFetchedResultsController(
      fetchRequest: Habit.orderedHabitsFetchRequest(forDate: interval.start),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    dayResultsFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayResult.resultsFetchRequest(from: interval.start, until: interval.end),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    dayTargetsFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayTarget.targetsFetchRequest(from: interval.start, until: interval.end),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    weekGoalsFetchResultsController = NSFetchedResultsController(
      fetchRequest: WeekGoal.goalsFetchRequest(from: interval.start, until: interval.end),
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
    
    fillHabitsAndCategories()
  }
  
  func fillHabitsAndCategories() {
    let habits = habitsFetchResultsController.fetchedObjects ?? []
    var possibleСategories = (categoriesFetchResultsController.fetchedObjects ?? []).map { CategoryWrapper.category(category: $0) }
    if habits.contains(where: { $0.category == nil }) {
      possibleСategories.append(.uncategorized)
    }
    categories = possibleСategories
  }
}

extension StatisticsIntervalData: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith diff: CollectionDifference<NSManagedObjectID>) {
    fillHabitsAndCategories()
  }
}

