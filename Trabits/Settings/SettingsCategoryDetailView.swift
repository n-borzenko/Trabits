//
//  SettingsCategoryDetailView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 15/12/2023.
//

import SwiftUI

struct CategoryDetailHabitView: View {
  @ObservedObject var habit: Habit
  
  var body: some View {
    let weekGoal = habit.sortedWeekGoals.first
    let dayTarget = habit.sortedDayTargets.first
    let hasDetailsRow = (weekGoal?.count ?? 0) > 0 || (dayTarget?.count ?? 1) > 1
    
    return NavigationLink(value: habit) {
      VStack(alignment: .leading, spacing: 4) {
        Text(habit.title ?? "")
          .padding(0)
        if hasDetailsRow {
          HabitDetailsRowView(dayTarget: dayTarget, weekGoal: weekGoal)
        }
      }
    }
    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20))
  }
}

struct SettingsCategoryDetailView: View {
  @EnvironmentObject var navigationCoordinator: NavigationCoordinator
  @Environment(\.managedObjectContext) var context
  @State private var isEditorVisible = false
  @State private var isHabitsSectionExpanded = false
  @ObservedObject var category: Category
  
  var body: some View {
    let habitsCount = category.habits?.count ?? 0
    List {
      Section("Title") {
        SettingsListItem(backgroundColor: category.color) {
          Text(category.title ?? "")
        }
      }
      
      Section {
        SettingsListItem(backgroundColor: .neutral5) {
          DisclosureGroup(
            "^[\(habitsCount) \("habit")](inflect: true)",
            isExpanded: habitsCount == 0 ? .constant(false) : $isHabitsSectionExpanded
          ) {
            ForEach(category.getSortedHabits()) { habit in
              SettingsListItem(backgroundColor: habit.color?.withAlphaComponent(0.7)) {
                CategoryDetailHabitView(habit: habit)
              }
            }
          }
          .tint(Color(uiColor: habitsCount == 0 ? .clear : .contrast))
        }
      }
      
      Section(footer: HStack {
        Text("Habits in the category will not be deleted")
          .font(.footnote)
          .frame(minWidth: 0, maxWidth: .infinity)
          .multilineTextAlignment(.center)
      }) {
        SettingsListItem(backgroundColor: .neutral5) {
          Button(role: .destructive, action: deleteCategory) {
            Text("Delete category")
              .frame(minWidth: 0, maxWidth: .infinity)
          }
          .buttonStyle(.borderless)
        }
      }
    }
    .listStyle(.grouped)
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .background(Color(uiColor: .systemBackground))
    .navigationTitle("Category")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Edit") {
          isEditorVisible.toggle()
        }
      }
    }
    .sheet(isPresented: $isEditorVisible) {
      CategoryEditorView(category: category)
    }
  }
  
  private func deleteCategory() {
    var categories: [Category] = []
    do {
      let fetchRequest = Category.orderedCategoriesFetchRequest(startingFrom: category.order - 1)
      fetchRequest.includesSubentities = false
      categories = try context.fetch(fetchRequest)
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
    
    if !categories.isEmpty {
      for index in 0..<categories.endIndex {
        categories[index].order += 1
      }
    }
    context.delete(category)
    saveChanges()
    navigationCoordinator.path.removeLast()
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
  var category: Category? = nil
  do {
    category = try context.fetch(Category.fetchRequest()).first
  } catch {}
  
  let navigationCoordinator = NavigationCoordinator()
  
  return NavigationStack(path: .constant(navigationCoordinator.path)) {
    SettingsCategoryDetailView(category: category!)
  }
  .environment(\.managedObjectContext, context)
  .environmentObject(navigationCoordinator)
}
