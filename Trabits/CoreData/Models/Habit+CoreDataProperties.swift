//
//  Habit+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 20/06/2023.
//
//

import UIKit
import CoreData

protocol HabitObjective {
  var count: Int32 { get set }
  var applicableFrom: Date? { get set }
}

extension Habit: Identifiable {
  @NSManaged var title: String?
  @NSManaged var order: Int32
  @NSManaged var color: UIColor?
  @NSManaged var createdAt: Date?
  @NSManaged var archivedAt: Date?
  @NSManaged var category: Category?
  @NSManaged var dayResults: NSSet?
  @NSManaged var dayTargets: NSSet?
  @NSManaged var weekGoals: NSSet?
  
  @objc var categoryTitle: String {
    category?.title ?? "Uncategorized"
  }
  
  public override func awakeFromInsert() {
    setPrimitiveValue(NSDate(), forKey: #keyPath(Habit.createdAt))
    super.awakeFromInsert()
  }
  
  var sortedWeekGoals: [WeekGoal] {
    weekGoals?.sortedArray(using: [NSSortDescriptor(key: "applicableFrom", ascending: false)]) as? [WeekGoal] ?? []
  }
  
  var sortedDayTargets: [DayTarget] {
    dayTargets?.sortedArray(using: [NSSortDescriptor(key: "applicableFrom", ascending: false)]) as? [DayTarget] ?? []
  }
}

extension Habit {
  @nonobjc class func fetchRequest() -> NSFetchRequest<Habit> {
    return NSFetchRequest<Habit>(entityName: "Habit")
  }

  @nonobjc class func orderedHabitsFetchRequest(startingFrom position: Int32? = nil) -> NSFetchRequest<Habit> {
    let request = fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    if let position {
      request.predicate = NSPredicate(format: "self.order >= %@", NSNumber(value: position))
    }
    return request
  }
  
  @nonobjc class func categoryOrderedHabitsFetchRequest(categoryObjectID: NSManagedObjectID) -> NSFetchRequest<Habit> {
    let request = fetchRequest()
    request.predicate = NSPredicate(format: "self.category == %@", categoryObjectID)
    request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    return request
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

// MARK: Generated accessors for dayTargets
extension Habit {
  @objc(addDayTargetsObject:)
  @NSManaged func addToDayTargets(_ value: DayTarget)
  
  @objc(removeDayTargetsObject:)
  @NSManaged func removeFromDayTargets(_ value: DayTarget)
  
  @objc(addDayTargets:)
  @NSManaged func addToDayTargets(_ values: NSSet)
  
  @objc(removeDayTargets:)
  @NSManaged func removeFromDayTargets(_ values: NSSet)
}

// MARK: Generated accessors for weekGoals
extension Habit {
  @objc(addWeekGoalsObject:)
  @NSManaged func addToWeekGoals(_ value: WeekGoal)
  
  @objc(removeWeekGoalsObject:)
  @NSManaged func removeFromWeekGoals(_ value: WeekGoal)
  
  @objc(addWeekGoals:)
  @NSManaged func addToWeekGoals(_ values: NSSet)
  
  @objc(removeWeekGoals:)
  @NSManaged func removeFromWeekGoals(_ values: NSSet)
}
