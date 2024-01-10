//
//  TrackerDayHabitListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 22/09/2023.
//

import UIKit

class TrackerDayHabitListCell: UICollectionViewListCell {
  func createConfiguration(habit: Habit, isGrouped: Bool, completion: @escaping () -> Void) {
    var newConfiguration = TrackerDayHabitContentConfiguration()
    newConfiguration.title = habit.title ?? ""
    newConfiguration.categoryTitle = isGrouped ? nil : habit.category?.title
    newConfiguration.color = (isGrouped ? habit.category?.color : habit.color) ?? .neutral10
    newConfiguration.completionCount = Int.random(in: 0...3)
    newConfiguration.completionTarget = Int.random(in: 1...3)
    newConfiguration.weekResult = Int.random(in: 0...7)
    newConfiguration.weekGoal = Int.random(in: 0...5)
    newConfiguration.progress = [.none, .completed, .partial, .completed, .completed, .none, .none]
    newConfiguration.isArchived = habit.archivedAt != nil
    newConfiguration.completion = completion
    contentConfiguration = newConfiguration
  }
}
