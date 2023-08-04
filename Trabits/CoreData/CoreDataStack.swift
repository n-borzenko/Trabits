//
//  CoreDataStack.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/07/2023.
//

import Foundation
import CoreData

final class CoreDataStack {
  private var modelName = "Trabits"

  private var storeURL: URL {
    let directoryURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    do {
      try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    } catch {
      print(error)
    }

    if #available(iOS 16.0, *) {
      return directoryURL.appending(path: "\(modelName).sqlite")
    } else {
      return directoryURL.appendingPathComponent("\(modelName).sqlite")
    }
  }

  lazy var storeDescription: NSPersistentStoreDescription = {
    let description = NSPersistentStoreDescription()
    description.shouldMigrateStoreAutomatically = true
    description.shouldInferMappingModelAutomatically = true
    description.url = storeURL
    return description
  }()

  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: modelName)
    container.persistentStoreDescriptions = [storeDescription]
    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    })
    return container
  }()

  init() {
    UIColorValueTransformer.register()
  }

  func saveContext() {
    let context = persistentContainer.viewContext
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
