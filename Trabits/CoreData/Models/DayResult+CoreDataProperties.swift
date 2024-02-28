//
//  DayResult+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/09/2023.
//
//

import Foundation
import CoreData

extension DayResult: Identifiable {
  @NSManaged var date: Date?
  @NSManaged var completionCount: Int32
  @NSManaged var habit: Habit?
}

extension DayResult {
  @nonobjc private class func fetchRequest() -> NSFetchRequest<DayResult> {
    return NSFetchRequest<DayResult>(entityName: "DayResult")
  }
  
  @nonobjc class func resultsFetchRequest(from startDate: Date, until endDate: Date) -> NSFetchRequest<DayResult> {
    let request = fetchRequest()
    let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
    let habitPredicate = NSPredicate(format: "habit.archivedAt == nil OR habit.archivedAt >= %@", startDate as NSDate)
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
    request.sortDescriptors = [NSSortDescriptor(keyPath: \DayResult.date, ascending: true)]
    return request
  }
  
  @nonobjc class func weekResultsFetchRequest(forDate date: Date) -> NSFetchRequest<DayResult> {
    let request = fetchRequest()
    guard let weekInterval = Calendar.current.weekInterval(for: date) else { return request }
    let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", weekInterval.start as NSDate, weekInterval.end as NSDate)
    let habitPredicate = NSPredicate(format: "habit.archivedAt == nil OR habit.archivedAt >= %@", date as NSDate)
    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, habitPredicate])
    request.sortDescriptors = [NSSortDescriptor(keyPath: \DayResult.date, ascending: true)]
    return request
  }
}
