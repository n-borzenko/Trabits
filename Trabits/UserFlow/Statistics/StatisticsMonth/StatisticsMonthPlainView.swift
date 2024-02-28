//
//  StatisticsMonthPlainView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 25/02/2024.
//

import SwiftUI

struct StatisticsMonthPlainView<TopView: View>: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @ObservedObject var monthData: StatisticsMonthData
  
  var width: Double = 0.0
  @ViewBuilder var topView: () -> TopView
  
  var body: some View {
    Section("Habits") {
      topView()
      ForEach(monthData.habitsWithResults) { item in
        StatisticsListItem {
          StatisticsHabitView(habit: item.habit, results: item.results) {
            StatisticsMonthHabitProgressView(
              monthLength: item.results.monthLength,
              monthResult: item.results.monthResult,
              color: item.habit.color
            )
          } chart: {
            StatisticsMonthHabitChartView(
              month: monthData.month,
              extendedMonth: monthData.extendedMonth,
              results: item.results,
              title: item.habit.title,
              color: item.habit.color,
              width: width
            )
          }
        }
      }
    }
    .id("habits")
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  let monthInterval = Calendar.current.monthInterval(for: Date())!
  let monthData = StatisticsMonthData(month: monthInterval, context: context)!
  
  return StatisticsMonthPlainView(monthData: monthData) { }
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
