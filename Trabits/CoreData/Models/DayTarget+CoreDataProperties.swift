//
//  DayTarget+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 27/11/2023.
//
//

import Foundation
import CoreData

extension DayTarget: Identifiable, HabitObjective {
  @NSManaged var applicableFrom: Date?
  @NSManaged var count: Int32
  @NSManaged var habit: Habit?
}

extension DayTarget {
  @nonobjc class func fetchRequest() -> NSFetchRequest<DayTarget> {
    return NSFetchRequest<DayTarget>(entityName: "DayTarget")
  }
}
