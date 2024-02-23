//
//  StatisticsWeekData.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/02/2024.
//

import Foundation
import CoreData

struct StatisticsResults {
  enum DayProgress {
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
  
  var dayTarget: DayTarget?
  var weekGoal: WeekGoal?
  var weekResult: Int = 0
  var progress: [DayProgress] = Array(repeating: .none(target: 1), count: 7)
}

class StatisticsWeekData: NSObject, ObservableObject {
  
  let week: DateInterval
  
  private let context: NSManagedObjectContext
  private var habitsFetchResultsController: NSFetchedResultsController<Habit>!
  private var categoriesFetchResultsController: NSFetchedResultsController<Category>!
  private var dayResultsFetchResultsController: NSFetchedResultsController<DayResult>!
  private var dayTargetsFetchResultsController: NSFetchedResultsController<DayTarget>!
  private var weekGoalsFetchResultsController: NSFetchedResultsController<WeekGoal>!
  
  enum CategoryWrapper: Identifiable, Hashable {
    case category(category: Category)
    case uncategorized
    
    var id: Self {
      return self
    }
  }
  
  struct HabitWithResults: Identifiable {
    var habit: Habit
    var results: StatisticsResults
    
    var id: ObjectIdentifier {
      habit.id
    }
  }
  
  @Published private(set) var habitsWithResults: [HabitWithResults] = []
  @Published private(set) var categories: [CategoryWrapper] = []
  
  init(week: DateInterval, context: NSManagedObjectContext) {
    self.week = week
    self.context = context
    super.init()
    configureFetchedResultsControllers()
  }
  
  func configureFetchedResultsControllers() {
    categoriesFetchResultsController = NSFetchedResultsController(
      fetchRequest: Category.orderedCategoriesFetchRequest(forDate: week.start),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    habitsFetchResultsController = NSFetchedResultsController(
      fetchRequest: Habit.orderedHabitsFetchRequest(forDate: week.start),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    dayResultsFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayResult.weekResultsFetchRequest(forDate: week.start),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    dayTargetsFetchResultsController = NSFetchedResultsController(
      fetchRequest: DayTarget.targetsUntilNextWeekFetchRequest(forDate: week.start),
      managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil
    )
    weekGoalsFetchResultsController = NSFetchedResultsController(
      fetchRequest: WeekGoal.goalsUntilNextWeekFetchRequest(forDate: week.start),
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
    habitsWithResults = habits.map {
      HabitWithResults(habit: $0, results: getHabitData(habit: $0))
    }
  }
  
  private func getHabitData(habit: Habit) -> StatisticsResults {
    var results = StatisticsResults()
    var completions = Array(repeating: 0, count: 7)
    
    guard let dayResults = dayResultsFetchResultsController.fetchedObjects,
          let dayTargets = dayTargetsFetchResultsController.fetchedObjects,
          let weekGoals = weekGoalsFetchResultsController.fetchedObjects else { return results }
    
    let filteredDayResults = dayResults.filter({ $0.habit == habit })
    for dayResult in filteredDayResults {
      guard dayResult.completionCount > 0, let resultDate = dayResult.date else { continue }
      let index = (Calendar.current.component(.weekday, from: resultDate) + 7 - Calendar.current.firstWeekday) % 7
      completions[index] = Int(dayResult.completionCount)
    }
    
    let filteredDayTargets = dayTargets.filter({ $0.habit == habit })
    let lastWeekDay = Calendar.current.date(byAdding: .day, value: -1, to: week.end)
    var currentDate = week.end
    var targetsIndex = filteredDayTargets.count - 1
    
    while currentDate > week.start && targetsIndex >= 0 {
      guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
      currentDate = newDate
      
      while let targetDate = filteredDayTargets[targetsIndex].applicableFrom, targetDate > currentDate {
        targetsIndex -= 1
      }
      
      if let lastWeekDay, currentDate == lastWeekDay {
        results.dayTarget = filteredDayTargets[targetsIndex]
      }
      
      let index = (Calendar.current.component(.weekday, from: currentDate) + 7 - Calendar.current.firstWeekday) % 7
      let targetCount = Int(filteredDayTargets[targetsIndex].count)
      if completions[index] > 0  {
        results.progress[index] = completions[index] >= targetCount ? .completed(completed: completions[index], target: targetCount) : .partial(completed: completions[index], target: targetCount)
      } else {
        results.progress[index] = .none(target: targetCount)
      }
    }
    
    if let filteredWeekGoal = weekGoals.last(where: { $0.habit == habit }) {
      results.weekGoal = filteredWeekGoal
    }
    results.weekResult = results.progress.filter({ item in
      return if case .completed(completed: _, target: _) = item { true } else { false }
    }).count
    
    return results
  }
}

extension StatisticsWeekData: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith diff: CollectionDifference<NSManagedObjectID>) {
    fillHabitsAndCategories()
  }
}
