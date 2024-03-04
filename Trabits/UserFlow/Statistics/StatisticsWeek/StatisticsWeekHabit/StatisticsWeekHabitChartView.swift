//
//  StatisticsWeekHabitChartView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/02/2024.
//

import SwiftUI

struct StatisticsWeekHabitChartView: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var results: StatisticsWeekResults
  var title: String?
  var color: UIColor?

  private let height = 110.0
  private let barWidth = 16.0
  private let barSpacing = 32.0

  private var maxValue: Double {
    Double(results.progress.reduce(into: 0) {
      switch $1 {
      case let .completed(completed: completed, target: target): $0 = max($0, completed, target)
      case let .partial(completed: _, target: target): $0 = max($0, target)
      case let .none(target: target): $0 = max($0, target)
      }
    })
  }

  private var hasData: Bool {
    results.progress.first {
      switch $0 {
      case .completed, .partial: return true
      case .none: return false
      }
    } != nil
  }

  var body: some View {
    let width = (barSpacing + barWidth) * 7

    return ZStack(alignment: .top) {
      if hasData {
        targetChart(maxValue: maxValue)
          .frame(width: width, height: height)
          .accessibilityHidden(true)
    }

      HStack(alignment: .bottom, spacing: 0) {
        ForEach(Array(results.progress.enumerated()), id: \.offset) { index, progress in
          let details = progress.details
          let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7

          VStack(spacing: 4) {
            bar(maxValue: maxValue, details: details, weekdayIndex: weekdayIndex)
            Text("\(Calendar.current.veryShortStandaloneWeekdaySymbols[weekdayIndex])")
              .font(.caption)
              .foregroundColor(Color(uiColor: .secondaryLabel))
              .dynamicTypeSize(...DynamicTypeSize.accessibility3)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel(
            """
            \(details.value.formatted(.number.rounded()))
            \(details.target > 0 ? "of \(details.target.formatted(.number.rounded())) " : "")
            on \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex])
            """
          )
        }
      }
      .frame(width: width)
      .accessibilityHidden(!hasData)

      if !hasData {
        Text("No records for this week")
          .font(.footnote)
          .foregroundColor(Color(uiColor: .secondaryLabel))
          .multilineTextAlignment(.center)
          .frame(height: height, alignment: .center)
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityChartDescriptor(self)
    .accessibilityHint("""
      Swipe up or down to select an audio graph action, then double tap to activate.
      Double tap and hold, wait or the sound, then drag to hear data values.
    """)
  }

  @ViewBuilder private func targetChart(maxValue: Double) -> some View {
    Path { path in
      let startDetails = results.progress[0].details
      let startOffsetX = barSpacing / 2 + barWidth / 2
      path.move(to: CGPoint(x: startOffsetX, y: height - height * (startDetails.target / maxValue) - 1))
      var previousTarget = startDetails.target
      for index in 1..<results.progress.count {
        let details = results.progress[index].details
        let point = CGPoint(
          x: startOffsetX + (barSpacing + barWidth) * Double(index),
          y: height - height * (details.target / maxValue) - 1
        )
        if previousTarget > 1 && details.target > 1 {
          path.addLine(to: point)
        } else {
          path.move(to: point)
        }
        previousTarget = details.target
      }
    }
    .stroke(Color.neutral30, style: StrokeStyle(lineWidth: 2, dash: [2]))
  }

  @ViewBuilder private func bar(
    maxValue: Double,
    details: StatisticsDayProgress.StatisticsDayProgressDetails,
    weekdayIndex: Int
  ) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
        .fill(Color(uiColor: color ?? .neutral10))
      RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
        .stroke(Color.contrast, lineWidth: 1)
    }
    .frame(width: barWidth, height: height * (details.value / maxValue))
    .frame(height: height, alignment: .bottom)
    .opacity(details.isCompleted ? 1.0 : 0.4)
    .padding(.horizontal, barSpacing / 2)
    .overlay {
      if details.value > 0 {
        Text("\(details.value.formatted(.number.rounded()))")
          .font(.caption2)
          .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
          .foregroundColor(Color(uiColor: .secondaryLabel))
          .position(
            x: barSpacing / 2 + barWidth / 2,
            y: height - height * (details.value / maxValue) - 12
          )
          .accessibilityShowsLargeContentViewer {
            Text(
              """
              \(details.value.formatted(.number.rounded())) on
              \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex])
              """
            )
          }
      }
    }
  }
}

extension StatisticsWeekHabitChartView: AXChartDescriptorRepresentable {
  func makeChartDescriptor() -> AXChartDescriptor {
    let xAxis = AXCategoricalDataAxisDescriptor(
      title: "Day of the week",
      categoryOrder: (0...6).map {
        Calendar.current.standaloneWeekdaySymbols[($0 + Calendar.current.firstWeekday - 1) % 7]
      }
    )

    let yAxis = AXNumericDataAxisDescriptor(
      title: "Progress",
      range: 0...100,
      gridlinePositions: [],
      valueDescriptionProvider: { "\($0)%" }
    )

    let weekString = StatisticsRouter.generateTitle(
      contentType: statisticsRouter.currentState.contentType,
      date: statisticsRouter.currentState.date
    )

    return AXChartDescriptor(
      title: "Habit \(title ?? "") results \(weekString)",
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
    let dataPoints = results.progress.enumerated().map { index, progress in
      let details = progress.details
      let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7
      let targetMessage = details.target > 0 ? "of \(details.target.formatted(.number.rounded())) " : ""

      return AXDataPoint(
        x: Calendar.current.standaloneWeekdaySymbols[weekdayIndex],
        y: min(details.value * 100 / details.target, 100),
        additionalValues: [],
        label: "\(details.value.formatted(.number.rounded())) completions \(targetMessage)"
      )
    }
    return [AXDataSeriesDescriptor(name: title ?? "", isContinuous: false, dataPoints: dataPoints)]
  }

  private func getChartSummary() -> String {
    guard hasData else { return "No records for this week" }

    let completed = results.progress.filter { $0.details.isCompleted }.count
    let partiallyCompleted = results.progress.filter { progress in
      let details = progress.details
      return !details.isCompleted && details.value > 0
    }.count
    return "\(completed) targets completed, \(partiallyCompleted) targets partially completed"
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var habit: Habit?
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}

  let statisticsRouter = StatisticsRouter()
  let results = StatisticsWeekResults(
    dayTarget: habit?.sortedDayTargets.first,
    weekGoal: habit?.sortedWeekGoals.first,
    weekResult: 4,
    progress: [
      .completed(completed: 3, target: 3),
      .completed(completed: 2, target: 2),
      .completed(completed: 2, target: 2),
      .partial(completed: 1, target: 2),
      .none(target: 6),
      .completed(completed: 6, target: 4),
      .none(target: Int(habit?.sortedDayTargets.first?.count ?? 4))
    ]
  )
  return StatisticsWeekHabitChartView(results: results, title: habit?.title, color: habit?.color)
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
