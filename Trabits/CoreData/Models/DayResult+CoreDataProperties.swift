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
  @nonobjc class func fetchRequest() -> NSFetchRequest<DayResult> {
    return NSFetchRequest<DayResult>(entityName: "DayResult")
  }

  @nonobjc class func singleDayPredicate(date: Date = Date()) -> NSPredicate {
    let interval = Calendar.current.dateInterval(of: .day, for: date)!
    return NSPredicate(format: "date >= %@ AND date < %@", interval.start as NSDate, interval.end as NSDate)
  }

  @nonobjc class func singleDayFetchRequest(date: Date = Date()) -> NSFetchRequest<DayResult> {
    let request = fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
    request.predicate = singleDayPredicate(date: date)
    request.fetchLimit = 1
    return request
  }
}
