//
//  Category+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/06/2023.
//
//

import UIKit
import CoreData

extension Category: Identifiable {
  @NSManaged var title: String?
  @NSManaged var color: UIColor?
  @NSManaged var habits: NSSet?

  @NSManaged var order: Int32
}

// MARK: Generated accessors for habits
extension Category {
  @objc(addHabitsObject:)
  @NSManaged func addToHabits(_ value: Habit)

  @objc(removeHabitsObject:)
  @NSManaged func removeFromHabits(_ value: Habit)

  @objc(addHabits:)
  @NSManaged func addToHabits(_ values: NSSet)

  @objc(removeHabits:)
  @NSManaged func removeFromHabits(_ values: NSSet)

  func getSortedHabits() -> [Habit] {
    let sortDescriptors = [
      NSSortDescriptor(keyPath: \Habit.archivedAt, ascending: true),
      NSSortDescriptor(keyPath: \Habit.order, ascending: true)
    ]
    return habits?.sortedArray(using: sortDescriptors) as? [Habit] ?? []
  }
}

extension Category {
  @nonobjc class func orderedCategoriesFetchRequest(startingFrom position: Int32? = nil) -> NSFetchRequest<Category> {
    let request = NSFetchRequest<Category>(entityName: "Category")
    request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.order, ascending: false)]
    if let position {
      request.predicate = NSPredicate(format: "order <= %@", NSNumber(value: position))
    }
    return request
  }

  @nonobjc class func orderedCategoriesFetchRequest(forDate date: Date) -> NSFetchRequest<Category> {
    let request = orderedCategoriesFetchRequest()
    request.predicate = NSPredicate(format: "SUBQUERY(habits, $h, $h.archivedAt == nil OR $h.archivedAt >= %@).@count > 0", date as NSDate)
    return request
  }
}
