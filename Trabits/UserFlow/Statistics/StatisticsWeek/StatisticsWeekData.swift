//
//  StatisticsWeekData.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/02/2024.
//

import Foundation
import CoreData

struct StatisticsWeekResults: StatisticsResults {
  var dayTarget: DayTarget?
  var weekGoal: WeekGoal?
  var weekResult: Int = 0
  var progress: [StatisticsDayProgress] = Array(repeating: .none(target: 1), count: 7)
}

class StatisticsWeekData: StatisticsIntervalData {
  var week: DateInterval { interval }
  
  @Published internal var habitsWithResults: [HabitWithResults<StatisticsWeekResults>] = []
  
  init(week: DateInterval, context: NSManagedObjectContext) {
    super.init(interval: week, context: context)
  }
  
  override func fillHabitsAndCategories() {
    super.fillHabitsAndCategories()
    habitsWithResults = (habitsFetchResultsController.fetchedObjects ?? []).map {
      HabitWithResults(habit: $0, results: getHabitData(habit: $0))
    }
  }
  
  private func getHabitData(habit: Habit) -> StatisticsWeekResults {
    var results = StatisticsWeekResults()
    var completions = Array(repeating: 0, count: 7)
    
    guard let dayResults = dayResultsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let dayTargets = dayTargetsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let weekGoals = weekGoalsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }) else { return results }
    
    for dayResult in dayResults {
      guard dayResult.completionCount > 0, let resultDate = dayResult.date else { continue }
      let index = (Calendar.current.component(.weekday, from: resultDate) + 7 - Calendar.current.firstWeekday) % 7
      completions[index] = Int(dayResult.completionCount)
    }
    
    var currentDate = week.end
    var targetsIndex = dayTargets.count - 1
    
    while currentDate > week.start && targetsIndex >= 0 {
      guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
      currentDate = newDate
      
      while let targetDate = dayTargets[targetsIndex].applicableFrom, targetDate > currentDate {
        targetsIndex -= 1
      }
      
      let index = (Calendar.current.component(.weekday, from: currentDate) + 7 - Calendar.current.firstWeekday) % 7
      let targetCount = Int(dayTargets[targetsIndex].count)
      if completions[index] > 0  {
        results.progress[index] = completions[index] >= targetCount ? .completed(completed: completions[index], target: targetCount) : .partial(completed: completions[index], target: targetCount)
      } else {
        results.progress[index] = .none(target: targetCount)
      }
    }
    
    if let dayTarget = dayTargets.last {
      results.dayTarget = dayTarget
    }
    if let weekGoal = weekGoals.last {
      results.weekGoal = weekGoal
    }
    
    results.weekResult = results.progress.filter({ item in
      return if case .completed(completed: _, target: _) = item { true } else { false }
    }).count
    
    return results
  }
}
