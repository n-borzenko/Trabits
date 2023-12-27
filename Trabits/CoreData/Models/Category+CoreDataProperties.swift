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
      NSSortDescriptor(keyPath: \Habit.order, ascending: true),
    ]
    return habits?.sortedArray(using: sortDescriptors) as? [Habit] ?? []
  }
}

extension Category {
  @nonobjc class func fetchRequest() -> NSFetchRequest<Category> {
    return NSFetchRequest<Category>(entityName: "Category")
  }
  
  @nonobjc class func singleCategoryFetchRequest(objectID: NSManagedObjectID) -> NSFetchRequest<Category> {
    let request = fetchRequest()
    request.predicate = NSPredicate(format: "self == %@", objectID)
    return request
  }

  @nonobjc class func orderedCategoriesFetchRequest(startingFrom position: Int32? = nil) -> NSFetchRequest<Category> {
    let request = fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.order, ascending: true)]
    if let position {
      request.predicate = NSPredicate(format: "self.order <= %@", NSNumber(value: position))
    }
    return request
  }

  @nonobjc class func nonEmptyCategoriesFetchRequest() -> NSFetchRequest<Category> {
    let request = orderedCategoriesFetchRequest()
    request.predicate = NSPredicate(format: "habits.@count > 0")
    return request
  }
}
