//
//  StatisticsWeekGroupedView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekGroupedView: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @ObservedObject var weekData: StatisticsWeekData
  
  var body: some View {
    let reorderedHabitsWithResults = weekData.categories.flatMap { categoryWrapper in
      let category = unwrapCategory(wrappedCategory: categoryWrapper)
      return weekData.habitsWithResults.filter { $0.habit.category == category }
    }
    
    return List {
      Section("Summary") {
        StatisticsListItem {
          StatisticsWeekSummaryHeaderView(weekData: weekData)
        }
        StatisticsListItem {
          StatisticsWeekSummaryGridView(habitsWithResults: reorderedHabitsWithResults, isGrouped: true)
        }
      }
      .id("Summary")
      
      ForEach(weekData.categories) { categoryWrapper in
        let category = unwrapCategory(wrappedCategory: categoryWrapper)
        Section(header: Text(category?.title ?? "Uncategorized")) {
          ForEach(weekData.habitsWithResults.filter { $0.habit.category == category }) { item in
            StatisticsListItem {
              StatisticsHabitView(habit: item.habit, results: item.results, isGrouped: true) {
                StatisticsWeekHabitGoalView(
                  weekGoal: Int(item.results.weekGoal?.count ?? 0), weekResult: item.results.weekResult, color: category?.color
                )
              } chart: {
                StatisticsWeekHabitChartView(results: item.results, color: category?.color)
              }
            }
          }
        }
      }
    }
    .headerProminence(.increased)
    .scrollContentBackground(.hidden)
    .listRowSpacing(6)
    .listStyle(.grouped)
    .overlay {
      if weekData.habitsWithResults.isEmpty {
        EmptyStateWrapperView(message: "List is empty. Please create a new habit.", actionTitle: "Add Habit") {
          statisticsRouter.navigateToStructureTab()
        }
      }
    }
  }
  
  private func unwrapCategory(wrappedCategory: StatisticsWeekData.CategoryWrapper) -> Category? {
    guard case let .category(category) = wrappedCategory else { return nil }
    return category
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  return StatisticsWeekGroupedView(weekData: StatisticsWeekData(week: weekInterval, context: context))
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
