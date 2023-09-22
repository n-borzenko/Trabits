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

  var orderPriority: Int {
    get { Int(order) }
    set { order = Int32(newValue) }
  }
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
}

extension Category {
  @nonobjc class func fetchRequest() -> NSFetchRequest<Category> {
    return NSFetchRequest<Category>(entityName: "Category")
  }

  @nonobjc class func orderedCategoriesFetchRequest() -> NSFetchRequest<Category> {
    let request = fetchRequest()
    request.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    return request
  }

  @nonobjc class func nonEmptyCategoriesFetchRequest() -> NSFetchRequest<Category> {
    let request = orderedCategoriesFetchRequest()
    request.predicate = NSPredicate(format: "habits.@count > 0")
    return request
  }
}
