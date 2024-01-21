//
//  StructureGroupedHabitsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/12/2023.
//

import SwiftUI

struct StructureGroupedHabitView: View {
  @ObservedObject var habit: Habit
  
  var body: some View {
    let weekGoal = habit.sortedWeekGoals.first
    let dayTarget = habit.sortedDayTargets.first
    let hasDetailsRow = (weekGoal?.count ?? 0) > 0 || (dayTarget?.count ?? 1) > 1
    
    return NavigationLink(value: habit) {
      VStack(alignment: .leading, spacing: 4) {
        if habit.archivedAt != nil {
          HabitArchivedStatusView()
        }
        Text(habit.title ?? "")
          .padding(0)
        if hasDetailsRow {
          HabitDetailsRowView(dayTarget: dayTarget, weekGoal: weekGoal)
        }
      }
    }
  }
}

struct StructureGroupedHabitsView: View {
  @Environment(\.managedObjectContext) var context
  @SectionedFetchRequest<String, Habit>(
    sectionIdentifier: \.categoryGroupIdentifier,
    sortDescriptors: [
      SortDescriptor(\.category?.order, order: .reverse),
      SortDescriptor(\.archivedAt, order: .forward),
      SortDescriptor(\.order, order: .forward)
    ]
  )
  private var groupedHabitSections: SectionedFetchResults<String, Habit>
  
  @Binding var isHabitEditorVisible: Bool
  
  var body: some View {
    List {
      ForEach(groupedHabitSections) { category in
        Section(header: Text(category.first?.category?.title ?? "Uncategorized")) {
          ForEach(category) { habit in
            StructureListItem(backgroundColor: habit.category?.color) {
              StructureGroupedHabitView(habit: habit)
            }
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
        }
        .headerProminence(.increased)
      }
    }
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .listStyle(.grouped)
    .overlay {
      if groupedHabitSections.isEmpty {
        EmptyStateWrapperView(message: "List is empty", actionTitle: "Add habit") {
          isHabitEditorVisible = true
        }
      }
    }
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
    StructureGroupedHabitsView(isHabitEditorVisible: .constant(false))
      .background(Color(uiColor: .systemBackground))
  }
  .environment(\.managedObjectContext, context)
}
