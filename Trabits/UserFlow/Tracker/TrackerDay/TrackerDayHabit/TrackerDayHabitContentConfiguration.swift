//
//  TrackerDayHabitContentConfiguration.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/01/2024.
//

import UIKit

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
