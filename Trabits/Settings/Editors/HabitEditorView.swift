//
//  HabitEditorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 27/11/2023.
//

import SwiftUI
import CoreData

enum HabitEditorPath {
  case none
  case category
}

struct HabitEditorDraft: Equatable {
  var title = ""
  var colorIndex = 0
  var dayTarget = 1
  var resetAllDayTargetIsOn = false
  var weekGoal = 0
  var resetAllWeekGoalsIsOn = false
}

struct HabitEditorView: View {
  @Environment(\.managedObjectContext) var context
  @Environment(\.dismiss) var dismiss
  var habit: Habit?
  
  @State private var habitDraft = HabitEditorDraft()
  @State private var selectedCategory: Category?
  @State private var isValid: Bool = false
  @State private var isNew: Bool = true
  @State private var isInitiallySetUp: Bool = false
  @State private var path = NavigationPath()
  
  @FocusState private var focusedField: FocusedEditorField?
  
  var body: some View {
    NavigationStack(path: $path) {
      List {
        TitleSelectorView(title: $habitDraft.title, focusedField: $focusedField)
        ColorSelectorView(colorIndex: $habitDraft.colorIndex)
        CategorySelectorView(category: selectedCategory)
        DayTargetSelectorView(
          dayTarget: $habitDraft.dayTarget,
          resetIsOn: $habitDraft.resetAllDayTargetIsOn,
          isNew: isNew
        )
        WeekGoalSelectorView(
          weekGoal: $habitDraft.weekGoal,
          resetIsOn: $habitDraft.resetAllWeekGoalsIsOn,
          isNew: isNew
        )
      }
      .navigationDestination(for: HabitEditorPath.self) { selectedPath in
        if selectedPath == .category {
          CategoryPickerView(selectedCategory: $selectedCategory)
        }
      }
      .navigationTitle(isNew ? "New Habit" : "Edit Habit")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            saveHabit()
            dismiss()
          }
          .disabled(!isValid)
        }
      }
      .onAppear { 
        setupHabitDraft()
        focusedField = .title
      }
      .onChange(of: habitDraft) { _ in validate() }
    }
  }
}

extension HabitEditorView {
  private func setupHabitDraft() {
    guard !isInitiallySetUp else { return }
    isInitiallySetUp = true
    
    guard let habit else { return }
    isNew = false
    isValid = true
    if let color = habit.color {
      habitDraft.colorIndex = PastelPalette.colors.firstIndex(of: color) ?? 0
    }
    habitDraft.dayTarget = Int(habit.sortedDayTargets.first?.count ?? 1)
    habitDraft.weekGoal = Int(habit.sortedWeekGoals.first?.count ?? 0)
    habitDraft.title = habit.title ?? ""
    selectedCategory = habit.category
  }
  
  private func validate() {
    if !habitDraft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      isValid = true
    } else {
      isValid = false
    }
  }
  
  private func saveHabit() {
    guard isValid else { return }
    
    if let habit {
      updateExistingHabit(habit: habit)
    } else {
      createNewHabit()
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
  
  private func createNewHabit() {
    var habitsCount = 0
    do {
      let fetchRequest = Habit.orderedHabitsFetchRequest()
      fetchRequest.includesSubentities = false
      habitsCount = try context.count(for: fetchRequest)
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
    
    let habit = Habit(context: context)
    habit.title = habitDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    habit.color = PastelPalette.colors[habitDraft.colorIndex]
    habit.category = selectedCategory
    habit.order = Int32(habitsCount)
    habit.dayResults = Set<DayResult>() as NSSet
    
    let weekGoal = WeekGoal(context: context)
    weekGoal.count = Int32(habitDraft.weekGoal)
    weekGoal.habit = habit
    
    let dayTarget = DayTarget(context: context)
    dayTarget.count = Int32(habitDraft.dayTarget)
    dayTarget.habit = habit
    
    do {
      try context.obtainPermanentIDs(for: [habit])
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
  
  private func updateExistingHabit(habit: Habit) {
    habit.title = habitDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)
    habit.color = PastelPalette.colors[habitDraft.colorIndex]
    habit.category = selectedCategory
    updateExistingWeekGoal(habit: habit)
    updateExistingDayTarget(habit: habit)
  }
  
  private func updateExistingDayTarget(habit: Habit) {
    if habitDraft.resetAllDayTargetIsOn {
      // set new initial value
      habit.dayTargets?.forEach {
        context.delete($0 as! DayTarget)
      }
      let dayTarget = DayTarget(context: context)
      dayTarget.count = Int32(habitDraft.dayTarget)
      dayTarget.habit = habit
      return
    }
    
    let sortedDayTargets = habit.sortedDayTargets
    guard habit.sortedDayTargets.count >= 1, habit.sortedDayTargets[0].count != habitDraft.dayTarget else {
      // last saved value is the same as in the habit draft
      return
    }
    
    let currentDayTarget = sortedDayTargets[0]
    guard let applicableFrom = currentDayTarget.applicableFrom,
          Calendar.current.isDateInToday(applicableFrom) else {
      // create new item as last record was not made today
      let dayTarget = DayTarget(context: context)
      dayTarget.count = Int32(habitDraft.dayTarget)
      dayTarget.applicableFrom = Calendar.current.startOfDay(for: Date())
      dayTarget.habit = habit
      return
    }
    
    guard sortedDayTargets.count >= 2, sortedDayTargets[1].count != habitDraft.dayTarget else {
      // previous value is the same as in the habit draft
      context.delete(currentDayTarget)
      return
    }
    
    // rewrite today value
    currentDayTarget.count = Int32(habitDraft.dayTarget)
  }
  
  private func updateExistingWeekGoal(habit: Habit) {
    if habitDraft.resetAllWeekGoalsIsOn {
      // set new initial value
      habit.weekGoals?.forEach {
        context.delete($0 as! WeekGoal)
      }
      let weekGoal = WeekGoal(context: context)
      weekGoal.count = Int32(habitDraft.weekGoal)
      weekGoal.habit = habit
      return
    }
    
    let sortedWeekGoals = habit.sortedWeekGoals
    guard sortedWeekGoals.count >= 1, sortedWeekGoals[0].count != habitDraft.weekGoal else {
      // last saved value is the same as in the habit draft
      return
    }
    
    let currentWeekGoal = sortedWeekGoals[0]
    guard let applicableFrom = currentWeekGoal.applicableFrom,
          Calendar.current.isDateInToday(applicableFrom) else {
      // create new item as last record was not made today
      let weekGoal = WeekGoal(context: context)
      weekGoal.count = Int32(habitDraft.weekGoal)
      weekGoal.applicableFrom = Calendar.current.startOfDay(for: Date())
      weekGoal.habit = habit
      return
    }
    
    guard sortedWeekGoals.count >= 2, sortedWeekGoals[1].count != habitDraft.weekGoal else {
      // previous value is the same as in the habit draft
      context.delete(currentWeekGoal)
      return
    }
    
    // rewrite today value
    currentWeekGoal.count = Int32(habitDraft.weekGoal)
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var habit: Habit? = nil
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}
  
  return HabitEditorView(habit: habit)
    .environment(\.managedObjectContext, context)
}
