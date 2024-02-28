//
//  CoreDataStack.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/07/2023.
//

import Foundation
import CoreData

struct PersistenceController {
  static let shared = PersistenceController()

  static var preview: PersistenceController = {
    let controller = PersistenceController(inMemory: true)
    controller.addCategories(viewContext: controller.container.viewContext)
    controller.addHabit(viewContext: controller.container.viewContext)
    return controller
  }()

  let container: NSPersistentContainer

  init(inMemory: Bool = false) {
    UIColorValueTransformer.register()

    container = NSPersistentContainer(name: PersistenceController.modelName)
    container.persistentStoreDescriptions = [PersistenceController.storeDescription]
    if inMemory {
      container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
    }
    container.loadPersistentStores { _, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
  }

  private static let modelName = "Trabits"

  private static var storeURL: URL {
    let directoryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    do {
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    } catch {
      print(error)
    }
    return directoryURL.appending(path: "\(modelName).sqlite")
  }

  private static var storeDescription: NSPersistentStoreDescription = {
    let description = NSPersistentStoreDescription()
    description.shouldMigrateStoreAutomatically = true
    description.shouldInferMappingModelAutomatically = true
    description.url = storeURL
    return description
  }()

  func saveContext() {
    let context = container.viewContext
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}

extension PersistenceController {
  private func addHabit(viewContext: NSManagedObjectContext) {
    var category: Category? = nil
    do {
      category = try viewContext.fetch(Category.orderedCategoriesFetchRequest()).first
    } catch {}

    let newHabit1 = Habit(context: viewContext)
    newHabit1.order = 0
    newHabit1.title = "Test habit"
    newHabit1.color = .apricot
    newHabit1.createdAt = Date()

    let weekGoal11 = WeekGoal(context: viewContext)
    weekGoal11.count = 4
    weekGoal11.habit = newHabit1

    let weekGoal12 = WeekGoal(context: viewContext)
    weekGoal12.applicableFrom = Calendar.current.date(byAdding: .day, value: -5, to: Date())
    weekGoal12.count = 5
    weekGoal12.habit = newHabit1

    let dayTarget11 = DayTarget(context: viewContext)
    dayTarget11.count = 3
    dayTarget11.applicableFrom = Date()
    dayTarget11.habit = newHabit1

    let dayTarget12 = DayTarget(context: viewContext)
    dayTarget12.count = 2
    dayTarget12.applicableFrom = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    dayTarget12.habit = newHabit1

    let dayTarget13 = DayTarget(context: viewContext)
    dayTarget13.count = 1
    dayTarget13.applicableFrom = Calendar.current.date(byAdding: .day, value: -5, to: Date())
    dayTarget13.habit = newHabit1

    newHabit1.category = category
    newHabit1.dayResults = Set<DayResult>() as NSSet

    let newHabit2 = Habit(context: viewContext)
    newHabit2.order = 1
    newHabit2.title = "Test habit 2"
    newHabit2.color = .sage
    newHabit2.createdAt = Date()

    let dayTarget21 = DayTarget(context: viewContext)
    dayTarget21.count = 1
    dayTarget21.applicableFrom = Calendar.current.date(byAdding: .day, value: -2, to: Date())
    dayTarget21.habit = newHabit2

    newHabit2.category = category
    newHabit2.dayResults = Set<DayResult>() as NSSet

    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
  }

  private func addCategories(viewContext: NSManagedObjectContext) {
    let newCategory1 = Category(context: viewContext)
    newCategory1.title = "Test category 1"
    newCategory1.order = 0
    newCategory1.color = .azure

    let newCategory2 = Category(context: viewContext)
    newCategory2.title = "Test category 2"
    newCategory2.order = 1
    newCategory2.color = .lavender

    do {
      try viewContext.save()
    } catch {
      let nsError = error as NSError
      fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }
  }
}
