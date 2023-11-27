//
//  Habit+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 20/06/2023.
//
//

import Foundation
import CoreData

extension Habit: Identifiable {
  @NSManaged var title: String?
  @NSManaged var order: Int32
  @NSManaged var category: Category?
  @NSManaged var dayResults: NSSet?
  
  var orderPriority: Int {
    get { Int(order) }
    set { order = Int32(newValue) }
  }
}

// MARK: Generated accessors for dayResults
extension Habit {
  @objc(addDayResultsObject:)
  @NSManaged func addToDayResults(_ value: DayResult)
  
  @objc(removeDayResultsObject:)
  @NSManaged func removeFromDayResults(_ value: DayResult)
  
  @objc(addDayResults:)
  @NSManaged func addToDayResults(_ values: NSSet)
  
  @objc(removeDayResults:)
  @NSManaged func removeFromDayResults(_ values: NSSet)
}

extension Habit {
  @nonobjc class func fetchRequest() -> NSFetchRequest<Habit> {
    return NSFetchRequest<Habit>(entityName: "Habit")
  }

  @nonobjc class func orderedHabitsFetchRequest() -> NSFetchRequest<Habit> {
    let request = fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    return request
  }
  
  @nonobjc class func categoryOrderedHabitsFetchRequest(categoryObjectID: NSManagedObjectID) -> NSFetchRequest<Habit> {
    let request = fetchRequest()
    request.predicate = NSPredicate(format: "self.category == %@", categoryObjectID)
    request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    return request
  }
}
