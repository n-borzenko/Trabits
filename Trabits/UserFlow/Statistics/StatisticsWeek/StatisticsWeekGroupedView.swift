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
              StatisticsWeekHabitChartView(
                results: item.results,
                title: item.habit.title,
                color: category?.color
              )
            }
          }
        }
      }
    }
  }
  
  private func unwrapCategory(wrappedCategory: StatisticsIntervalData.CategoryWrapper) -> Category? {
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
