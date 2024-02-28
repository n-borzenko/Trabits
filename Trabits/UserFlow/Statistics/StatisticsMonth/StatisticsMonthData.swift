//
//  StatisticsMonthData.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/02/2024.
//

import Foundation
import CoreData

struct StatisticsMonthResults: StatisticsResults {
  struct StatisticsWeekProgress {
    var weekGoal: Int = 0
    var weekResult: Int = 0
  }
  
  var dayTarget: DayTarget?
  var weekGoal: WeekGoal?
  
  var monthLength: Int = 0
  var monthResult: Int = 0
  
  var weekProgress: [StatisticsWeekProgress] = []
  var progress: [StatisticsDayProgress] = []
}

class StatisticsMonthData: StatisticsIntervalData {
  var extendedMonth: DateInterval { interval }
  var month: DateInterval
  
  @Published internal var habitsWithResults: [HabitWithResults<StatisticsMonthResults>] = []
  
  init?(month: DateInterval, context: NSManagedObjectContext) {
    self.month = month
    guard let start = Calendar.current.weekInterval(for: month.start)?.start,
          let lastDayOfTheMonth = Calendar.current.date(byAdding: .day, value: -1, to: month.end),
          let end = Calendar.current.weekInterval(for: lastDayOfTheMonth)?.end else { return nil }
    super.init(interval: DateInterval(start: start, end: end), context: context)
  }
  
  override func fillHabitsAndCategories() {
    super.fillHabitsAndCategories()
    habitsWithResults = (habitsFetchResultsController.fetchedObjects ?? []).map {
      HabitWithResults(habit: $0, results: getHabitData(habit: $0))
    }
  }
  
  private func getHabitData(habit: Habit) -> StatisticsMonthResults {
    var results = StatisticsMonthResults()
    
    guard let lastDayOfTheMonth = Calendar.current.date(byAdding: .day, value: -1, to: month.end) else { return results }
    results.monthLength = Calendar.current.component(.day, from: lastDayOfTheMonth)
    let startWeekOfYear = Calendar.current.component(.weekOfYear, from: month.start)
    let weekCount = Calendar.current.component(.weekOfYear, from: lastDayOfTheMonth) - startWeekOfYear + 1

    guard let dayResults = dayResultsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let dayTargets = dayTargetsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }),
          let weekGoals = weekGoalsFetchResultsController.fetchedObjects?.filter({ $0.habit == habit }) else { return results }

    var completions = Array(repeating: 0, count: 7 * weekCount)
    for dayResult in dayResults {
      guard dayResult.completionCount > 0, let resultDate = dayResult.date else { continue }
      let weekdayIndex = (Calendar.current.component(.weekday, from: resultDate) + 7 - Calendar.current.firstWeekday) % 7
      let weekIndex = Calendar.current.component(.weekOfYear, from: resultDate) - startWeekOfYear
      let index = weekdayIndex + weekIndex * 7
      completions[index] = Int(dayResult.completionCount)
    }

    var currentDate = extendedMonth.end
    var targetsIndex = dayTargets.count - 1
    var index = completions.count
    var monthProgress: [StatisticsDayProgress] = Array(repeating: .none(target: 1), count: 7 * weekCount)
    var monthResult = 0
    while currentDate > extendedMonth.start && targetsIndex >= 0 {
      guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
      currentDate = newDate
      index -= 1
      
      while let targetDate = dayTargets[targetsIndex].applicableFrom, targetDate > currentDate {
        targetsIndex -= 1
      }
      
      let targetCount = Int(dayTargets[targetsIndex].count)
      if completions[index] > 0  {
        if completions[index] >= targetCount  {
          monthProgress[index] = .completed(completed: completions[index], target: targetCount)
          if currentDate >= month.start && currentDate < month.end {
            monthResult += 1
          }
        } else {
          monthProgress[index] = .partial(completed: completions[index], target: targetCount)
        }
      } else {
        monthProgress[index] = .none(target: targetCount)
      }
    }
    results.progress = monthProgress
    results.monthResult = monthResult
    
    if let dayTarget = dayTargets.last {
      results.dayTarget = dayTarget
    }

    if let weekGoal = weekGoals.last {
      results.weekGoal = weekGoal
    }
    
    var weekProgress: [StatisticsMonthResults.StatisticsWeekProgress] = []
    for weekIndex in 0..<weekCount {
      var weekResult = 0
      for weekdayIndex in 0..<7 {
        if case .completed(completed: _, target: _) = monthProgress[weekdayIndex + weekIndex * 7] {
          weekResult += 1
        }
      }
      
      var weekGoal: WeekGoal? = nil
      if let nextWeekDate = Calendar.current.date(byAdding: .day, value: (weekIndex + 1) * 7, to: extendedMonth.start) {
        weekGoal = weekGoals.last(where: { $0.applicableFrom == nil || $0.applicableFrom! < nextWeekDate })
      }
      weekProgress.append(StatisticsMonthResults.StatisticsWeekProgress(weekGoal: Int(weekGoal?.count ?? 0), weekResult: weekResult))
    }
    results.weekProgress = weekProgress
    
    return results
  }
}
