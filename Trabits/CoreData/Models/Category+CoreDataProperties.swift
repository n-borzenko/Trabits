//
//  Category+CoreDataProperties.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/06/2023.
//
//

import UIKit
import CoreData


extension Category {

  @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
    return NSFetchRequest<Category>(entityName: "Category")
  }

  @NSManaged public var title: String?
  @NSManaged public var color: UIColor?
  @NSManaged public var habits: NSSet?

  @NSManaged public var order: Int32

  var orderPriority: Int {
    get { Int(order) }
    set { order = Int32(newValue) }
  }
}

// MARK: Generated accessors for habits
extension Category {

  @objc(addHabitsObject:)
  @NSManaged public func addToHabits(_ value: Habit)

  @objc(removeHabitsObject:)
  @NSManaged public func removeFromHabits(_ value: Habit)

  @objc(addHabits:)
  @NSManaged public func addToHabits(_ values: NSSet)

  @objc(removeHabits:)
  @NSManaged public func removeFromHabits(_ values: NSSet)

}

extension Category : Identifiable {

}
