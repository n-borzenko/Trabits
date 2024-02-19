//
//  StatisticsWeekSummaryGridView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekSummaryRowView<Title: View, Chart: View, Goal: View>: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  
  @ViewBuilder var title: () -> Title
  @ViewBuilder var chart: () -> Chart
  @ViewBuilder var goal: () -> Goal
  
  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      GridRow {
        title()
          .gridCellColumns(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      GridRow {
        chart()
          .gridColumnAlignment(.leading)
        goal()
          .gridColumnAlignment(.trailing)
      }
      Divider()
    } else {
      GridRow {
        title()
          .gridColumnAlignment(.leading)
        chart()
          .gridColumnAlignment(.trailing)
        goal()
          .gridColumnAlignment(.trailing)
      }
      Divider()
    }
  }
}

struct StatisticsWeekSummaryChartView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  var results: StatisticsResults
  var color: UIColor?
  
  var body: some View {
    HStack(spacing: dynamicTypeSize.isAccessibilitySize ? 6 : 4) {
      ForEach(Array(results.progress.enumerated()), id: \.offset) { _, result in
        let properties = getProperties(result: result)
        let circleColor = properties.hasBorder ? Color(uiColor: color ?? .neutral10) : Color.neutral5
        ZStack {
          Circle()
            .fill(circleColor)
            .opacity(properties.hasBorder && !properties.hasDot ? 0.5 : 1)
          Circle()
            .stroke(Color.contrast, lineWidth: dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            .opacity(properties.hasBorder ? 1 : 0)
          Circle()
            .fill(Color(.contrast))
            .frame(
              width: dynamicTypeSize.isAccessibilitySize ? 8 : 4,
              height: dynamicTypeSize.isAccessibilitySize ? 8 : 4
            )
            .opacity(properties.hasDot ? 1 : 0)
        }
        .frame(
          width: dynamicTypeSize.isAccessibilitySize ? 24 : 16,
          height: dynamicTypeSize.isAccessibilitySize ? 24 : 16
        )
      }
    }
  }
  
  private func getProperties(result: StatisticsResults.DayProgress) -> (hasBorder: Bool, hasDot: Bool) {
    switch result {
    case .completed(completed: _, target: _): return (hasBorder: true, hasDot: true)
    case .partial(completed: _, target: _): return (hasBorder: true, hasDot: false)
    case .none(target: _): return (hasBorder: false, hasDot: false)
    }
  }
}

struct StatisticsWeekSummaryGridView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  
  var habitsWithResults: [StatisticsWeekData.HabitWithResults]
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
