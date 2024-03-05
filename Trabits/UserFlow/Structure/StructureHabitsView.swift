//
//  StructureHabitsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

struct StructureHabitView: View {
  @ObservedObject var habit: Habit

  var body: some View {
    let weekGoal = habit.sortedWeekGoals.first
    let dayTarget = habit.sortedDayTargets.first
    let hasDetailsRow = habit.category != nil ||
    (weekGoal?.count ?? 0) > 0 || (dayTarget?.count ?? 1) > 1

    return NavigationLink(value: habit) {
      VStack(alignment: .leading, spacing: 4) {
        if habit.archivedAt != nil {
          HabitArchivedStatusView()
        }
        Text(habit.title ?? "")
          .padding(0)
        if hasDetailsRow {
          HabitDetailsRowView(category: habit.category, dayTarget: dayTarget, weekGoal: weekGoal)
        }
      }
    }
  }
}

struct StructureHabitsView: View {
  @Environment(\.managedObjectContext) var context
  @Environment(\.editMode) var editMode
  @FetchRequest(
    sortDescriptors: [
      SortDescriptor(\.archivedAt, order: .forward),
      SortDescriptor(\.order, order: .forward)
    ]
  )
  private var habits: FetchedResults<Habit>
  @Binding var isHabitEditorVisible: Bool

  var body: some View {
    List {
      ForEach(habits) { habit in
        StructureListItem(backgroundColor: habit.color) {
          StructureHabitView(habit: habit)
        }
        .moveDisabled(habit.archivedAt != nil)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
          if habit.archivedAt != nil {
            Button {
              unarchiveHabit(habit)
            } label: {
              Label("Unarchive", systemImage: "shippingbox.and.arrow.backward")
            }
            .tint(Color(uiColor: .neutral30))
          } else {
            Button {
              archiveHabit(habit)
            } label: {
              Label("Archive", systemImage: "archivebox")
            }
            .tint(Color(uiColor: .neutral40))
          }
        }
      }
      .onMove(perform: reorderHabits)
    }
    .id(editMode?.wrappedValue)
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .listStyle(.plain)
    .overlay {
      if habits.isEmpty {
        EmptyStateWrapperView(message: "List is empty. Please create a new habit.", actionTitle: "Add Habit") {
          isHabitEditorVisible = true
        }
      }
    }
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

  private func unarchiveHabit(_ habit: Habit) {
    var notArchivedHabitsCount = 0
    do {
      let fetchRequest = Habit.orderedHabitsFetchRequest(startingFrom: 0)
      fetchRequest.includesSubentities = false
      notArchivedHabitsCount = try context.count(for: fetchRequest)
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }

    habit.archivedAt = nil
    habit.order = Int32(notArchivedHabitsCount)
    saveChanges()
  }

  private func archiveHabit(_ habit: Habit) {
    var habits: [Habit] = []
    do {
      let fetchRequest = Habit.orderedHabitsFetchRequest(startingFrom: habit.order + 1)
      fetchRequest.includesSubentities = false
      habits = try context.fetch(fetchRequest)
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }

    if !habits.isEmpty {
      for index in 0..<habits.endIndex {
        habits[index].order -= 1
      }
    }
    habit.archivedAt = Date()
    habit.order = -1
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
    StructureHabitsView(isHabitEditorVisible: .constant(false))
      .background(Color(uiColor: .systemBackground))
  }
  .environment(\.managedObjectContext, context)
}
