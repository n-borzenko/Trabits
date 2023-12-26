//
//  CategorySelectorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 03/12/2023.
//

import SwiftUI

struct CategorySelectorView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  var category: Category?
  
  var body: some View {
    let layout = dynamicTypeSize < .accessibility1 ? AnyLayout(HStackLayout(alignment: .center)) : AnyLayout(VStackLayout(alignment: .leading))
    
    Section("Category") {
      NavigationLink(value: HabitEditorPath.category) {
        layout {
          Text("Selected")
          Spacer()
          Group {
            if let category {
              HStack {
                Circle()
                  .fill(Color(uiColor: category.color ?? .neutral5))
                  .frame(width: 16, height: 16)
                Text(category.title ?? "")
              }
            } else {
              Text("None")
            }
          }
          .foregroundColor(.secondary)
        }
      }
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var category: Category? = nil
  do {
    category = try context.fetch(Category.orderedCategoriesFetchRequest()).first
  } catch { }
  
  return NavigationStack {
    List {
      CategorySelectorView(category: category)
    }
  }
}
