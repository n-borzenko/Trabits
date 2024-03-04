//
//  StatisticsMonthHabitChartView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 26/02/2024.
//

import SwiftUI

struct StatisticsMonthHabitChartView: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var month: DateInterval
  var extendedMonth: DateInterval

  var results: StatisticsMonthResults
  var title: String?
  var color: UIColor?

  var width: Double = 0.0

  private var hasData: Bool {
    results.progress.first {
      switch $0 {
      case .completed, .partial: return true
      case .none: return false
      }
    } != nil
  }

  var body: some View {
    VStack {
      ForEach(Array(results.weekProgress.enumerated()), id: \.offset) { weekIndex, weekProgress in
        rowLayout(width: width) {
          HStack {
            ForEach(0..<7) { index in
              let date = Calendar.current.date(byAdding: .day, value: weekIndex * 7 + index, to: extendedMonth.start)
              if let date {
                let details = results.progress[weekIndex * 7 + index].details
                let isCurrentMonth = date >= month.start && date < month.end
                let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7

                cell(
                  details: details,
                  day: Calendar.current.component(.day, from: date),
                  isCurrentMonth: isCurrentMonth
                )
                  .accessibilityElement(children: .ignore)
                  .accessibilityLabel(
                    """
                    \(results.progress[weekIndex * 7 + index].message)
                    on \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex]),
                    \(date.formatted(date: .abbreviated, time: .omitted))
                    """
                  )
                  .accessibilityShowsLargeContentViewer {
                    Text(
                      """
                      \(results.progress[weekIndex * 7 + index].message)
                      \(date.formatted(date: .numeric, time: .omitted))
                      """
                    )
                  }
              }
            }
          }
          HStack {
            Spacer(minLength: 0)
            StatisticsHabitSmallWeekGoalView(
              weekGoal: weekProgress.weekGoal,
              weekResult: weekProgress.weekResult,
              color: color
            )
          }
        }
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 20)
    .frame(maxWidth: 500)
    .accessibilityElement(children: .contain)
    .accessibilityChartDescriptor(self)
    .accessibilityHint(
      """
      Swipe up or down to select an audio graph action, then double tap to activate.
      Double tap and hold, wait or the sound, then drag to hear data values.
      """
    )
  }

  @ViewBuilder private func rowLayout(width: Double, @ViewBuilder content: () -> some View) -> some View {
    let layout = dynamicTypeSize.isAccessibilitySize && width < 500 ?
    AnyLayout(VStackLayout(alignment: .center)) :
    AnyLayout(HStackLayout(alignment: .center))

    layout {
      content()
    }
  }

  @ViewBuilder private func cell(
    details: StatisticsDayProgress.StatisticsDayProgressDetails,
    day: Int,
    isCurrentMonth: Bool
  ) -> some View {
    let size = dynamicTypeSize.isAccessibilitySize ? 42.0 : 30.0
    let dotSize = dynamicTypeSize.isAccessibilitySize ? 8.0 : 4.0
    let circleColor = details.value > 0 ? Color(uiColor: color ?? .neutral10) : Color.neutral5
    let lineWidth = dynamicTypeSize.isAccessibilitySize ? 2.0 : 1.0

    ZStack {
      Circle()
        .fill(circleColor)
        .opacity(!details.isCompleted && details.value > 0 ? 0.5 : 1)
      Circle()
        .stroke(Color.contrast, lineWidth: lineWidth)
        .opacity(details.value > 0 ? 1 : 0)
      Text("\(day)")
        .font(.caption2)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .alignmentGuide(VerticalAlignment.center) { $0[VerticalAlignment.center] + 4 }
      Circle()
        .fill(.contrast)
        .frame(width: dotSize, height: dotSize)
        .opacity(details.isCompleted ? 1 : 0)
        .alignmentGuide(VerticalAlignment.center) {
          $0[VerticalAlignment.center] - (dynamicTypeSize.isAccessibilitySize ? 10 : 8)
        }
    }
    .opacity(isCurrentMonth ? 1 : 0.2)
    .frame(width: size, height: size)
  }
}

extension StatisticsMonthHabitChartView: AXChartDescriptorRepresentable {
  func makeChartDescriptor() -> AXChartDescriptor {
    let dates = results.weekProgress.enumerated().flatMap { weekIndex, _ in
      (0..<7).map { index in
        let date = Calendar.current.date(byAdding: .day, value: weekIndex * 7 + index, to: extendedMonth.start)
        guard let date else { return "" }
        let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7
        let weekdaySymbol = Calendar.current.standaloneWeekdaySymbols[weekdayIndex]
        return "\(date.formatted(date: .abbreviated, time: .omitted)), \(weekdaySymbol)"
      }
    }
    let xAxis = AXCategoricalDataAxisDescriptor(
      title: "Day of the month",
      categoryOrder: dates
    )

    let yAxis = AXNumericDataAxisDescriptor(
      title: "Progress",
      range: 0...100,
      gridlinePositions: []
    ) {
      "\($0)%"
    }

    let monthString = StatisticsRouter.generateTitle(
      contentType: statisticsRouter.currentState.contentType,
      date: statisticsRouter.currentState.date
    )

    return AXChartDescriptor(
      title: "Habit \(title ?? "") results for \(monthString)",
      summary: getChartSummary(),
      xAxis: xAxis,
      yAxis: yAxis,
      series: getChartSeries()
    )
  }

  func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
    descriptor.summary = getChartSummary()
    descriptor.series = getChartSeries()
  }

  private func getChartSeries() -> [AXDataSeriesDescriptor] {
    let dataPoints: [AXDataPoint] = results.weekProgress.enumerated().flatMap { weekIndex, _ in
      (0..<7).compactMap { index in
        let resultIndex = weekIndex * 7 + index
        let date = Calendar.current.date(byAdding: .day, value: resultIndex, to: extendedMonth.start)
        guard let date else { return nil }
        let details = results.progress[resultIndex].details
        let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7
        let xValue =
          """
          \(date.formatted(date: .abbreviated, time: .omitted)),
          \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex])
          """

        return AXDataPoint(
          x: xValue,
          y: min(details.value * 100 / details.target, 100),
          additionalValues: [],
          label: "\(results.progress[resultIndex].message)"
        )
      }
    }
    return [AXDataSeriesDescriptor(name: title ?? "", isContinuous: false, dataPoints: dataPoints)]
  }

  private func getChartSummary() -> String {
    guard hasData else { return "No records for this week" }

    let weekResults = results.weekProgress.enumerated().map {
      $1.weekGoal > 0 ?
      """
      \($1.weekResult) of \($1.weekGoal) targets completed on week \($0 + 1),
      goal \($1.weekResult > $1.weekGoal ? "" : "not " )achieved
      """ :
      "\($1.weekResult) targets completed on week \($0 + 1)"
    }
    return weekResults.joined(separator: "; ")
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var habit: Habit?
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}

  let statisticsRouter = StatisticsRouter()
  let monthInterval = Calendar.current.monthInterval(for: Date())!
  let monthData = StatisticsMonthData(month: monthInterval, context: context)!
  let results = StatisticsMonthResults(
    dayTarget: habit?.sortedDayTargets.first,
    weekGoal: habit?.sortedWeekGoals.first,
    monthLength: 30,
    monthResult: 15,
    weekProgress: [
      StatisticsMonthResults.StatisticsWeekProgress(weekGoal: 4, weekResult: 4),
      StatisticsMonthResults.StatisticsWeekProgress(weekGoal: 0, weekResult: 0),
      StatisticsMonthResults.StatisticsWeekProgress(weekGoal: 0, weekResult: 3),
      StatisticsMonthResults.StatisticsWeekProgress(weekGoal: 6, weekResult: 7),
      StatisticsMonthResults.StatisticsWeekProgress(weekGoal: 4, weekResult: 0)
    ],
    progress: (0..<5).flatMap { _ in
      [
        .completed(completed: 3, target: 3),
        .completed(completed: 2, target: 2),
        .completed(completed: 2, target: 2),
        .partial(completed: 1, target: 2),
        .none(target: 6),
        .completed(completed: 6, target: 4),
        .none(target: Int(habit?.sortedDayTargets.first?.count ?? 4))
      ]
    }
  )

  return StatisticsMonthHabitChartView(
    month: monthData.month,
    extendedMonth: monthData.extendedMonth,
    results: results,
    title: habit?.title,
    color: habit?.color
  )
  .environment(\.managedObjectContext, context)
  .environmentObject(statisticsRouter)
}
