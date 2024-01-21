//
//  StructureHabitDetailView.swift
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

struct StructureHabitDetailView: View {
  @EnvironmentObject var structureRouter: StructureRouter
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.managedObjectContext) var context
  
  @State private var isEditorVisible = false
  @State private var isRemovingDataAlertVisible = false
  @State private var isDeletingHabitAlertVisible = false
  
  @ObservedObject var habit: Habit
  
  var body: some View {
    let isArchived = habit.archivedAt != nil
    
    List {
      Section("Title") {
        StructureListItem(backgroundColor: habit.color) {
          Text(habit.title ?? "")
        }
      }
      
      if let category = habit.category {
        Section("Category") {
          StructureListItem(backgroundColor: .neutral5) {
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
      
      Section("Status") {
        StructureListItem(backgroundColor: .neutral5) {
          HStack {
            Text(isArchived ? "Archived from \(Calendar.current.startOfDay(for: habit.archivedAt!).formatted(date: .abbreviated, time: .omitted))" : "Active")
            Spacer()
            Button(action: isArchived ? unarchiveHabit : archiveHabit) {
              Text(isArchived ? "Unarchive" : "Archive")
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                  RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.tint, lineWidth: dynamicTypeSize >= .accessibility1 ? 2 : 1)
                )
            }
          }
        }
      }
      
      Section {
        StructureListItem(backgroundColor: .neutral5) {
          Button(role: .destructive) {
            isRemovingDataAlertVisible = true
          } label: {
            Text("Remove all completion records")
              .frame(minWidth: 0, maxWidth: .infinity)
          }
          .buttonStyle(.borderless)
          .disabled((habit.dayResults?.count ?? 0) == 0)
          .alert("Remove all completion records", isPresented: $isRemovingDataAlertVisible) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive, action: removeCompletions)
          }
        }
        StructureListItem(backgroundColor: .neutral5) {
          Button(role: .destructive) {
            isDeletingHabitAlertVisible = true
          } label: {
            Text("Delete habit and all related data")
              .frame(minWidth: 0, maxWidth: .infinity)
          }
          .buttonStyle(.borderless)
          .alert("Delete habit", isPresented: $isDeletingHabitAlertVisible) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: deleteHabit)
          }
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
    .fullScreenCover(isPresented: $isEditorVisible) {
      HabitEditorView(habit: habit)
    }
  }
  
  private func unarchiveHabit() {
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
  
  private func archiveHabit() {
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
    structureRouter.path.removeLast()
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
  
  let structureRouter = StructureRouter()
  
  return NavigationStack(path: .constant(structureRouter.path)) {
    StructureHabitDetailView(habit: habit!)
  }
  .environment(\.managedObjectContext, context)
  .environmentObject(structureRouter)
}
