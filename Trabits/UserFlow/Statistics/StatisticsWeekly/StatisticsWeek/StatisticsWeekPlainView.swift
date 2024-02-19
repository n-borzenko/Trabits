//
//  StatisticsWeekPlainView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekPlainView: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @ObservedObject var weekData: StatisticsWeekData
  
  var body: some View {
    List {
      Section("Summary") {
        StatisticsListItem {
          StatisticsWeekSummaryHeaderView(weekData: weekData)
        }
        StatisticsListItem {
          StatisticsWeekSummaryGridView(habitsWithResults: weekData.habitsWithResults)
        }
      }
      .id("Summary")
      Section("Habits") {
        ForEach(weekData.habitsWithResults) { item in
          StatisticsListItem {
            StatisticsHabitView(habit: item.habit, results: item.results) {
              StatisticsWeekHabitGoalView(
                weekGoal: Int(item.results.weekGoal?.count ?? 0),
                weekResult: item.results.weekResult,
                color: item.habit.color
              )
            } chart: {
              StatisticsWeekHabitChartView(results: item.results, color: item.habit.color)
            }
          }
        }
      }
      .id("Details")
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
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  
  return StatisticsWeekPlainView(weekData: StatisticsWeekData(week: weekInterval, context: context))
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
