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
  @nonobjc private class func fetchRequest() -> NSFetchRequest<DayTarget> {
    return NSFetchRequest<DayTarget>(entityName: "DayTarget")
  }
  
  @nonobjc class func targetsFetchRequest(from startDate: Date, until endDate: Date) -> NSFetchRequest<DayTarget> {
    let request = fetchRequest()
    let datePredicate = NSPredicate(format: "applicableFrom == nil OR applicableFrom < %@", endDate as NSDate)
    let habitPredicate = NSPredicate(format: "habit.archivedAt == nil OR habit.archivedAt >= %@", startDate as NSDate)
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
    request.sortDescriptors = [NSSortDescriptor(keyPath: \DayTarget.applicableFrom, ascending: true)]
    return request
  }
  
  @nonobjc class func targetsUntilNextWeekFetchRequest(forDate date: Date) -> NSFetchRequest<DayTarget> {
    let request = fetchRequest()
    guard let weekInterval = Calendar.current.weekInterval(for: date) else { return request }
    let datePredicate = NSPredicate(format: "applicableFrom == nil OR applicableFrom < %@", weekInterval.end as NSDate)
    let habitPredicate = NSPredicate(format: "habit.archivedAt == nil OR habit.archivedAt >= %@", date as NSDate)
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
    request.sortDescriptors = [NSSortDescriptor(keyPath: \DayTarget.applicableFrom, ascending: true)]
    return request
  }
}
