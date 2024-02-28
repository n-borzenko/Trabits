//
//  StatisticsMonthGroupedView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 25/02/2024.
//

import SwiftUI

struct StatisticsMonthGroupedView<TopView: View>: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @ObservedObject var monthData: StatisticsMonthData
  
  var width: Double = 0.0
  @ViewBuilder var topView: () -> TopView
  
  var body: some View {
    ForEach(monthData.categories) { categoryWrapper in
      let category = unwrapCategory(wrappedCategory: categoryWrapper)
      Section(header: Text(category?.title ?? "Uncategorized")) {
        if let firstCategory = monthData.categories.first, categoryWrapper == firstCategory {
          topView()
        }
        
        ForEach(monthData.habitsWithResults.filter { $0.habit.category == category }) { item in
          StatisticsListItem {
            StatisticsHabitView(habit: item.habit, results: item.results, isGrouped: true) {
              StatisticsMonthHabitProgressView(
                monthLength: item.results.monthLength,
                monthResult: item.results.monthResult,
                color: category?.color
              )
            } chart: {
              StatisticsMonthHabitChartView(
                month: monthData.month,
                extendedMonth: monthData.extendedMonth,
                results: item.results,
                title: item.habit.title,
                color: category?.color,
                width: width
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
  let monthInterval = Calendar.current.monthInterval(for: Date())!
  let monthData = StatisticsMonthData(month: monthInterval, context: context)!
  
  return StatisticsMonthGroupedView(monthData: monthData) { }
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
