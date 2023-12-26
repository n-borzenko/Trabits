//
//  SettingsCategoriesView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

struct SettingsCategoryView: View {
  @ObservedObject var category: Category
  
  var body: some View {
    NavigationLink(value: category) {
      VStack(alignment: .leading, spacing: 2) {
        Text(category.title ?? "")
        if let count = category.habits?.count, count > 0 {
          Text("^[\(count) \("habit")](inflect: true)")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 1)
        }
      }
    }
  }
}

struct SettingsCategoriesView: View {
  @Environment(\.managedObjectContext) var context
  @FetchRequest(
    sortDescriptors: [SortDescriptor(\.order, order: .reverse)]
  )
  private var categories: FetchedResults<Category>
  
  var body: some View {
    List {
      ForEach(categories) { category in
        SettingsListItem(backgroundColor: category.color) {
          SettingsCategoryView(category: category)
        }
      }
      .onMove(perform: reorderCategories)
      .onDelete(perform: deleteCategories)
    }
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .listStyle(.plain)
  }
  
  private func reorderCategories(indices: IndexSet, destinationIndex: Int) {
    guard indices.count == 1, let sourceIndex = indices.first else { return }
    let category = categories[sourceIndex]
    if sourceIndex < destinationIndex {
      for index in (sourceIndex + 1)..<destinationIndex {
        categories[index].order += 1
      }
      category.order = -Int32(destinationIndex - 1)
    } else {
      for index in destinationIndex..<sourceIndex {
        categories[index].order -= 1
      }
      category.order = -Int32(destinationIndex)
    }
    saveChanges()
  }
  
  private func deleteCategories(indices: IndexSet) {
    guard indices.count == 1, let categoryIndex = indices.first else { return }
    let category = categories[categoryIndex]
    for index in categoryIndex.advanced(by: 1)..<categories.endIndex {
      categories[index].order += 1
    }
    context.delete(category)
    saveChanges()
  }
  
  private func saveChanges() {
    do {
      try context.save()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  return NavigationStack {
    SettingsCategoriesView()
      .background(Color(uiColor: .systemBackground))
  }
  .environment(\.managedObjectContext, context)
}
