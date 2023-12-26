//
//  SettingsHabitDetailView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 15/12/2023.
//

import SwiftUI

struct HabitDetailObjectivesView: View {
  var objectives: [HabitObjective]
  var imageName: String
  
  var body: some View {
    let items = Array(zip(objectives.indices, objectives))
    
    return ScrollView(.horizontal) {
      LazyHStack(spacing: 16) {
        ForEach(items, id: \.0) { index, objective in
          VStack(spacing: 4) {
            HStack(spacing: 4) {
              Image(systemName: imageName)
              Text("\(objective.count)")
            }
            if let startDate = objective.applicableFrom {
              Text("Since \(startDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
            } else {
              Text("Initial value")
                .font(.caption)
            }
          }
          .foregroundColor(Color(uiColor: index == 0 ? .label : .secondaryLabel))
          .padding(8)
          .background(Color(uiColor: .neutral5).opacity(0.7))
          .cornerRadius(8)
        }
      }
      .padding(.bottom, 4)
    }
    .listRowBackground(Color.clear)
    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
    .listRowSeparator(.hidden)
  }
}

struct SettingsHabitDetailView: View {
  @EnvironmentObject var navigationCoordinator: NavigationCoordinator
  @Environment(\.managedObjectContext) var context
  @State private var isEditorVisible = false
  @ObservedObject var habit: Habit
  
  var body: some View {
    List {
      Section("Title") {
        SettingsListItem(backgroundColor: habit.color) {
          Text(habit.title ?? "")
        }
      }
      
      if let category = habit.category {
        Section("Category") {
          SettingsListItem(backgroundColor: .neutral5) {
            HStack {
              Circle()
                .fill(Color(uiColor: category.color ?? .neutral5))
                .frame(width: 16, height: 16)
              Text(category.title ?? "")
            }
          }
        }
      }
      
      Section("Day targets") {
        HabitDetailObjectivesView(objectives: habit.sortedDayTargets, imageName: "target")
      }
      
      Section("Week goals") {
        HabitDetailObjectivesView(objectives: habit.sortedWeekGoals, imageName: "flame")
      }
      
      Section {
        SettingsListItem(backgroundColor: .neutral5) {
          Button(role: .destructive, action: removeCompletions) {
            Text("Remove all completion records")
              .frame(minWidth: 0, maxWidth: .infinity)
          }
          .buttonStyle(.borderless)
          .disabled((habit.dayResults?.count ?? 0) == 0)
        }
        SettingsListItem(backgroundColor: .neutral5) {
          Button(role: .destructive, action: deleteHabit) {
            Text("Delete habit and related data")
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
    .navigationTitle("Habit")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Edit") {
          isEditorVisible.toggle()
        }
      }
    }
    .sheet(isPresented: $isEditorVisible) {
      HabitEditorView(habit: habit)
    }
  }
  
  private func deleteHabit() {
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
    context.delete(habit)
    saveChanges()
    navigationCoordinator.path.removeLast()
  }
  
  private func removeCompletions() {
    habit.dayResults?.forEach {
      context.delete($0 as! DayResult)
    }
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
  var habit: Habit? = nil
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}
  
  let navigationCoordinator = NavigationCoordinator()
  
  return NavigationStack(path: .constant(navigationCoordinator.path)) {
    SettingsHabitDetailView(habit: habit!)
  }
  .environment(\.managedObjectContext, context)
  .environmentObject(navigationCoordinator)
}
