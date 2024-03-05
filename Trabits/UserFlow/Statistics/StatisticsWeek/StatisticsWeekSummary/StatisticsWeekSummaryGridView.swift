//
//  StatisticsWeekSummaryGridView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekSummaryGridView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @ObservedObject var weekData: StatisticsWeekData
  var isGrouped: Bool = false

  var body: some View {
    Grid {
      loopThroughHabits { item in
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

  @ViewBuilder private func loopThroughHabits(
    @ViewBuilder row: @escaping (StatisticsIntervalData.HabitWithResults<StatisticsWeekResults>) -> some View
  ) -> some View {
    if isGrouped {
      ForEach(weekData.categories) { categoryWrapper in
        let category = unwrapCategory(wrappedCategory: categoryWrapper)
        ForEach(weekData.habitsWithResults.filter { $0.habit.category == category }) { item in
          row(item)
        }
      }
    } else {
      ForEach(weekData.habitsWithResults) { item in
        row(item)
      }
    }
  }

  private func unwrapCategory(wrappedCategory: StatisticsIntervalData.CategoryWrapper) -> Category? {
    guard case let .category(category) = wrappedCategory else { return nil }
    return category
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  let weekData = StatisticsWeekData(week: weekInterval, context: context)
  return StatisticsWeekSummaryGridView(weekData: weekData)
    .environment(\.managedObjectContext, context)
}
