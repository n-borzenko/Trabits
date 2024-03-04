//
//  HabitWeekResults.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/02/2024.
//

import Foundation

struct HabitWeekResults: Hashable {
  enum DayProgress: String {
    case none = "not completed"
    case partial = "partially completed"
    case completed = "fully completed"
  }

  var completionTarget: Int = 1
  var completionCount: Int = 0
  var weekGoal: Int = 0
  var weekResult: Int = 0
  var progress: [DayProgress] = Array(repeating: .none, count: 7)

  func hash(into hasher: inout Hasher) {
    hasher.combine(completionTarget)
    hasher.combine(completionCount)
    hasher.combine(weekGoal)
    hasher.combine(weekResult)
    hasher.combine(progress)
  }

  static func == (lhs: HabitWeekResults, rhs: HabitWeekResults) -> Bool {
    lhs.completionTarget == rhs.completionTarget &&
    lhs.completionCount == rhs.completionCount &&
    lhs.weekGoal == rhs.weekGoal &&
    lhs.weekResult == rhs.weekResult &&
    lhs.progress == rhs.progress
  }

  var accessibilityShortDescription: String {
    var description = ""
    if completionTarget > 1 {
      description += "\(completionCount) of \(completionTarget) completed. "
    } else {
      description += completionCount == completionTarget ? "Completed. " : "Not completed. "
    }
    return description
  }

  var accessibilityLongDescription: String {
    var description = ""
    if weekGoal > 0 {
      description += "\(weekResult) of \(weekGoal) targets completed this week. "
    } else {
      description += "\(weekResult) targets completed this week. "
    }
    for index in 0..<progress.count {
      let weekdayIndex = Calendar.current.weekdayIndex(index)
      description += "\(progress[index].rawValue) on \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex]). "
    }
    return description
  }
}
