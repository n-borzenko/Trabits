//
//  TrackerDayHabitListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 22/09/2023.
//

import UIKit

class TrackerDayHabitListCell: UICollectionViewListCell {
  func createConfiguration(
    habit: Habit,
    isGrouped: Bool,
    weekResults: HabitWeekResults,
    completion: @escaping () -> Void
  ) {
    var newConfiguration = TrackerDayHabitContentConfiguration()
    newConfiguration.title = habit.title ?? ""
    newConfiguration.categoryTitle = isGrouped ? nil : habit.category?.title
    newConfiguration.color = (isGrouped ? habit.category?.color : habit.color) ?? .neutral10
    newConfiguration.isArchived = habit.archivedAt != nil
    newConfiguration.weekResults = weekResults
    newConfiguration.completion = completion
    contentConfiguration = newConfiguration
  }
}
