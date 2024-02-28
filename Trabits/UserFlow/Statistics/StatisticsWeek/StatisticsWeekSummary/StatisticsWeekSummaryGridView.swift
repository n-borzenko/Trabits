//
//  StatisticsWeekSummaryGridView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekSummaryGridView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  
  var habitsWithResults: [StatisticsWeekData.HabitWithResults<StatisticsWeekResults>]
  var isGrouped: Bool = false
  
  var body: some View {
    Grid {
      ForEach(habitsWithResults) { item in
        let color = isGrouped ? item.habit.category?.color : item.habit.color
        StatisticsWeekSummaryRowView {
          Text(item.habit.title ?? "")
            .font(.caption2)
            .truncationMode(.tail)
            .lineLimit(1)
        } chart: {
          StatisticsWeekSummaryChartView(results: item.results, color: color)
        } goal: {
          StatisticsHabitSmallWeekGoalView(
            weekGoal: Int(item.results.weekGoal?.count ?? 0), weekResult: item.results.weekResult, color: color
          )
        }
        .accessibilityElement(children: .contain)
      }
    }
    .padding(.horizontal, 8)
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  let weekData = StatisticsWeekData(week: weekInterval, context: context)
  return StatisticsWeekSummaryGridView(habitsWithResults: weekData.habitsWithResults)
    .environment(\.managedObjectContext, context)
}
