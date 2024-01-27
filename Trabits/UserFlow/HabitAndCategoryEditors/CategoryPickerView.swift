//
//  CategoryPickerView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 01/12/2023.
//

import SwiftUI
import CoreData

struct CategoryPickerView: View {
  @Binding var selectedCategory: Category?
  
  @FetchRequest(
    sortDescriptors: [SortDescriptor(\.order, order: .reverse)]
  ) var categories: FetchedResults<Category>
  @State private var isCategoryEditorPresented = false
  @State private var listSelectionRefreshingId = UUID()

  var body: some View {
    ScrollViewReader { proxy in
      List(selection: $selectedCategory) {
        Section {
          ForEach(categories, id: \.self) { category in
            HStack {
              Circle()
                .fill(Color(uiColor: category.color ?? .neutral5))
                .frame(width: 16, height: 16)
              Text(category.title ?? "")
              Spacer()
              if selectedCategory == category {
                Image(systemName: "checkmark")
                  .accessibilityHidden(true)
              }
            }
          }
        }
        .id(listSelectionRefreshingId)
        if !categories.isEmpty {
          Section {
            Button("Clear selection", role: .destructive) {
              selectedCategory = nil
              listSelectionRefreshingId = UUID()
            }
            .disabled(selectedCategory == nil)
          }
        }
      }
      .overlay {
        if categories.isEmpty {
          EmptyStateWrapperView(message: "List is empty. Please create a new category.", actionTitle: "Add Category") {
            isCategoryEditorPresented = true
          }
        }
      }
      .onAppear {
        if let selectedCategory {
          proxy.scrollTo(selectedCategory)
        }
      }
    }
    .navigationTitle("Categories")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Add category", systemImage: "plus") {
          isCategoryEditorPresented = true
        }
      }
    }
    .fullScreenCover(isPresented: $isCategoryEditorPresented) {
      CategoryEditorView()
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var category: Category? = nil
  do {
    category = try context.fetch(Category.orderedCategoriesFetchRequest()).first
  } catch {}
  
  return NavigationStack {
    CategoryPickerView(selectedCategory: .constant(category))
      .environment(\.managedObjectContext, context)
  }
}
