//
//  TrackerDayHabitContentConfiguration.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/01/2024.
//

import UIKit

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
      let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7
      description += "\(progress[index].rawValue) on \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex]). "
    }
    return description
  }
}

struct TrackerDayHabitContentConfiguration: UIContentConfiguration, Hashable {
  var title: String = ""
  var categoryTitle: String? = nil
  var color: UIColor = .clear
  var weekResults = HabitWeekResults()
  var isArchived: Bool = false
  var completion: (() -> Void)? = nil

  func makeContentView() -> UIView & UIContentView {
    return TrackerDayHabitContentView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> TrackerDayHabitContentConfiguration {
    return self
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
    hasher.combine(categoryTitle)
    hasher.combine(color)
    hasher.combine(weekResults)
    hasher.combine(isArchived)
  }
  
  static func == (lhs: TrackerDayHabitContentConfiguration, rhs: TrackerDayHabitContentConfiguration) -> Bool {
    lhs.title == rhs.title &&
    lhs.categoryTitle == rhs.categoryTitle &&
    lhs.color == rhs.color &&
    lhs.weekResults == rhs.weekResults &&
    lhs.isArchived == rhs.isArchived
  }
}
