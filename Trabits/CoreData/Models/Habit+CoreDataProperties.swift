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
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
    return NSFetchRequest<Habit>(entityName: "Habit")
  }

  @NSManaged public var title: String?
  @NSManaged public var order: Int32
  @NSManaged public var category: Category?

  public var orderPriority: Int {
    get { Int(order) }
    set { order = Int32(newValue) }
  }
}
