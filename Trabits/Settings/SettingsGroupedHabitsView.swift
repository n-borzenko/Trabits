//
//  SettingsGroupedHabitsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

struct SettingsGroupedHabitView: View {
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
  }
}

struct SettingsGroupedHabitsView: View {
  @Environment(\.managedObjectContext) var context
  @SectionedFetchRequest<String, Habit>(
    sectionIdentifier: \.categoryTitle,
    sortDescriptors: [
      SortDescriptor(\.category?.order, order: .reverse),
      SortDescriptor(\.order, order: .forward)
    ]
  )
  private var groupedHabitSections: SectionedFetchResults<String, Habit>
  
  var body: some View {
    List {
      ForEach(groupedHabitSections) { category in
        Section(header: Text(category.id)) {
          ForEach(category) { habit in
            SettingsListItem(backgroundColor: habit.category?.color) {
              SettingsGroupedHabitView(habit: habit)
            }
          }
          .onDelete(perform: { indicies in
            deleteHabits(indices: indicies, categoryTitle: category.id)
          })
        }
        .headerProminence(.increased)
      }
    }
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .listStyle(.grouped)
  }
  
  private func deleteHabits(indices: IndexSet, categoryTitle: String) {
    guard let category = groupedHabitSections.first(where: { $0.id == categoryTitle }),
          indices.count == 1, let habitIndex = indices.first else { return }
    let habit = category[habitIndex]
    
    var habits: [Habit] = []
    do {
      let fetchRequest = Habit.orderedHabitsFetchRequest(startingFrom: habit.order + 1)
      fetchRequest.includesSubentities = false
      habits = try context.fetch(fetchRequest)
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
    
    guard !habits.isEmpty else { return }
    for index in 0..<habits.endIndex {
      habits[index].order -= 1
    }
    context.delete(habit)
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
    SettingsGroupedHabitsView()
      .background(Color(uiColor: .systemBackground))
  }
  .environment(\.managedObjectContext, context)
}
