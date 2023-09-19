//
//  DayResult+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/09/2023.
//
//

import Foundation
import CoreData

extension DayResult {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<DayResult> {
    return NSFetchRequest<DayResult>(entityName: "DayResult")
  }

  @NSManaged public var date: Date?
  @NSManaged public var completedHabits: NSSet?

}

// MARK: Generated accessors for completedHabits
extension DayResult {

  @objc(addCompletedHabitsObject:)
  @NSManaged public func addToCompletedHabits(_ value: Habit)

  @objc(removeCompletedHabitsObject:)
  @NSManaged public func removeFromCompletedHabits(_ value: Habit)

  @objc(addCompletedHabits:)
  @NSManaged public func addToCompletedHabits(_ values: NSSet)

  @objc(removeCompletedHabits:)
  @NSManaged public func removeFromCompletedHabits(_ values: NSSet)

}

extension DayResult : Identifiable {

}
