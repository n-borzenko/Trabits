//
//  CategoryEditorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 04/12/2023.
//

import SwiftUI
import CoreData

struct CategoryEditorDraft: Equatable {
  var title = ""
  var colorIndex = 0
}

struct CategoryEditorView: View {
  @Environment(\.managedObjectContext) var context
  @Environment(\.dismiss) var dismiss
  var category: Category?

  @State private var categoryDraft = CategoryEditorDraft()
  @State private var isValid = false
  @State private var isNew = true

  @FocusState private var focusedField: FocusedEditorField?

  var body: some View {
    NavigationStack {
      List {
        TitleSelectorView(title: $categoryDraft.title, focusedField: $focusedField)
        ColorSelectorView(colorIndex: $categoryDraft.colorIndex)
      }
      .navigationTitle(isNew ? "New Category" : "Edit Category")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveCategory()
            dismiss()
          }
          .disabled(!isValid)
        }
      }
      .onAppear {
        setupCategoryDraft()
        focusedField = .title
      }
      .onChange(of: categoryDraft) { _ in validate() }
    }
  }
}

extension CategoryEditorView {
  private func setupCategoryDraft() {
    guard let category else { return }
    isNew = false
    isValid = true
    if let color = category.color {
      categoryDraft.colorIndex = PastelPalette.colors.firstIndex(of: color) ?? 0
    }
    categoryDraft.title = category.title ?? ""
  }

  private func validate() {
    if !categoryDraft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      isValid = true
    } else {
      isValid = false
    }
  }

  private func saveCategory() {
    guard isValid else { return }

    if let category {
      updateExistingCategory(category: category)
    } else {
      createNewCategory()
    }

    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }

  private func createNewCategory() {
    var categoriesCount = 0
    do {
      let fetchRequest = Category.orderedCategoriesFetchRequest()
      fetchRequest.includesSubentities = false
      categoriesCount = try context.count(for: fetchRequest)
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }

    let category = Category(context: context)
    category.title = categoryDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    category.color = PastelPalette.colors[categoryDraft.colorIndex]
    category.order = -Int32(categoriesCount)
    category.habits = Set<Habit>() as NSSet

    do {
      try context.obtainPermanentIDs(for: [category])
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }

  private func updateExistingCategory(category: Category) {
    category.title = categoryDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    category.color = PastelPalette.colors[categoryDraft.colorIndex]
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var category: Category?
  do {
    category = try context.fetch(Category.orderedCategoriesFetchRequest()).first
  } catch {}

  return CategoryEditorView(category: category)
    .environment(\.managedObjectContext, context)
}
