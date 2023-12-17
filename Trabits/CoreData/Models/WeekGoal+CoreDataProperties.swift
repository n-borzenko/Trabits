//
//  WeekGoal+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 27/11/2023.
//
//

import Foundation
import CoreData

extension WeekGoal: Identifiable, HabitObjective {
  @NSManaged var count: Int32
  @NSManaged var applicableFrom: Date?
  @NSManaged var habit: Habit?
}

extension WeekGoal {
  @nonobjc class func fetchRequest() -> NSFetchRequest<WeekGoal> {
    return NSFetchRequest<WeekGoal>(entityName: "WeekGoal")
  }
}
