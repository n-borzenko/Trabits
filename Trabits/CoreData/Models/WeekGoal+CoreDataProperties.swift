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
  @nonobjc private class func fetchRequest() -> NSFetchRequest<WeekGoal> {
    return NSFetchRequest<WeekGoal>(entityName: "WeekGoal")
  }
  
  @nonobjc class func goalsFetchRequest(from startDate: Date, until endDate: Date) -> NSFetchRequest<WeekGoal> {
    let request = fetchRequest()
    let datePredicate = NSPredicate(format: "applicableFrom == nil OR applicableFrom < %@", endDate as NSDate)
    let habitPredicate = NSPredicate(format: "habit.archivedAt == nil OR habit.archivedAt >= %@", startDate as NSDate)
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
    request.sortDescriptors = [NSSortDescriptor(keyPath: \WeekGoal.applicableFrom, ascending: true)]
    return request
  }
  
  @nonobjc class func goalsUntilNextWeekFetchRequest(forDate date: Date) -> NSFetchRequest<WeekGoal> {
    let request = fetchRequest()
    guard let weekInterval = Calendar.current.weekInterval(for: date) else { return request }
    let datePredicate = NSPredicate(format: "applicableFrom == nil OR applicableFrom < %@", weekInterval.end as NSDate)
    let habitPredicate = NSPredicate(format: "habit.archivedAt == nil OR habit.archivedAt >= %@", date as NSDate)
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
    request.sortDescriptors = [NSSortDescriptor(keyPath: \WeekGoal.applicableFrom, ascending: true)]
    return request
  }
}
