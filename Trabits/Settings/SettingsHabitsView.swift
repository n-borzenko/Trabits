//
//  SettingsHabitsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

struct SettingsHabitView: View {
  @ObservedObject var habit: Habit
  
  var body: some View {
    let weekGoal = habit.sortedWeekGoals.first
    let dayTarget = habit.sortedDayTargets.first
    let hasDetailsRow = habit.category != nil ||
    (weekGoal?.count ?? 0) > 0 || (dayTarget?.count ?? 1) > 1
    
    return NavigationLink(value: habit) {
      VStack(alignment: .leading, spacing: 4) {
        Text(habit.title ?? "")
          .padding(0)
        if hasDetailsRow {
          HabitDetailsRowView(category: habit.category, dayTarget: dayTarget, weekGoal: weekGoal)
        }
      }
    }
  }
}

struct SettingsHabitsView: View {
  @Environment(\.managedObjectContext) var context
  @FetchRequest(
    sortDescriptors: [SortDescriptor(\.order, order: .forward)]
  )
  private var habits: FetchedResults<Habit>
  
  var body: some View {
    List {
      ForEach(habits) { habit in
        SettingsListItem(backgroundColor: habit.color) {
          SettingsHabitView(habit: habit)
        }
      }
      .onMove(perform: reorderHabits)
      .onDelete(perform: deleteHabits)
    }
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .listStyle(.plain)
  }
  
  private func reorderHabits(indices: IndexSet, destinationIndex: Int) {
    guard indices.count == 1, let sourceIndex = indices.first else { return }
    let habit = habits[sourceIndex]
    if sourceIndex < destinationIndex {
      for index in (sourceIndex + 1)..<destinationIndex {
        habits[index].order -= 1
      }
      habit.order = Int32(destinationIndex - 1)
    } else {
      for index in destinationIndex..<sourceIndex {
        habits[index].order += 1
      }
      habit.order = Int32(destinationIndex)
    }
    saveChanges()
  }
  
  private func deleteHabits(indices: IndexSet) {
    guard indices.count == 1, let habitIndex = indices.first else { return }
    let habit = habits[habitIndex]
    for index in habitIndex.advanced(by: 1)..<habits.endIndex {
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
    SettingsHabitsView()
      .background(Color(uiColor: .systemBackground))
  }
  .environment(\.managedObjectContext, context)
}
