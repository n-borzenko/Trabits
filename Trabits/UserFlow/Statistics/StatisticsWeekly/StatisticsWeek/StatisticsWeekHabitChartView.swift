//
//  StatisticsWeekHabitChartView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/02/2024.
//

import SwiftUI

struct StatisticsWeekHabitChartView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  var results: StatisticsResults
  var color: UIColor?
  
  private let height = 110.0
  private let barWidth = 16.0
  private let barSpacing = 32.0
  
  var body: some View {
    let maxValue = Double(results.progress.reduce(into: 0) {
      switch $1 {
      case let .completed(completed: completed, target: target): $0 = max($0, completed, target)
      case let .partial(completed: _, target: target): $0 = max($0, target)
      case let .none(target: target): $0 = max($0, target)
      }
    })
    
    let hasData = results.progress.first(where: {
      switch $0 {
      case .completed(completed: _, target: _), .partial(completed: _, target: _): return true
      case .none(target: _): return false
      }
    }) != nil
    
    let width = (barSpacing + barWidth) * 7
    
    return ZStack(alignment: .top) {
      if hasData {
        targetChart(maxValue: maxValue)
          .frame(width: width, height: height)
      }
      
      HStack(alignment: .bottom, spacing: 0) {
        ForEach(Array(results.progress.enumerated()), id: \.offset) { index, progress in
          let details = getProgressDetails(progress: progress)
          let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7
          
          VStack(spacing: 4) {
            bar(maxValue: maxValue, details: details, weekdayIndex: weekdayIndex)
            Text("\(Calendar.current.veryShortStandaloneWeekdaySymbols[weekdayIndex])")
              .font(.caption)
              .foregroundColor(Color(uiColor: .secondaryLabel))
              .dynamicTypeSize(...DynamicTypeSize.accessibility3)
          }
        }
      }
      .frame(width: width)
      
      if !hasData {
        Text("No records for this week")
          .font(.footnote)
          .foregroundColor(Color(uiColor: .secondaryLabel))
          .multilineTextAlignment(.center)
          .frame(height: height, alignment: .center)
      }
    }
  }
  
  private func getProgressDetails(progress: StatisticsResults.DayProgress) -> (isCompleted: Bool, value: Double, target: Double) {
    switch progress {
    case let .completed(completed: value, target: target): return (isCompleted: true, value: Double(value), target: Double(target))
    case let .partial(completed: value, target: target): return (isCompleted: false, value: Double(value), target: Double(target))
    case let .none(target: target): return (isCompleted: false, value: 0.0, target: Double(target))
    }
  }
  
  @ViewBuilder private func targetChart(maxValue: Double) -> some View {
    Path { path in
      let startDetails = getProgressDetails(progress: results.progress[0])
      let startOffsetX = barSpacing / 2 + barWidth / 2
      path.move(to: CGPoint(x: startOffsetX, y: height - height * (startDetails.target / maxValue) - 1))
      var previousTarget = startDetails.target
      for i in 1..<results.progress.count {
        let details = getProgressDetails(progress: results.progress[i])
        let point = CGPoint(x: startOffsetX + (barSpacing + barWidth) * Double(i), y: height - height * (details.target / maxValue) - 1)
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
  
  @ViewBuilder private func bar(maxValue: Double, details: (isCompleted: Bool, value: Double, target: Double), weekdayIndex: Int) -> some View {
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
            Text("\(details.value.formatted(.number.rounded())) on \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex])")
          }
      }
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var habit: Habit? = nil
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}
  
  let results = StatisticsResults(dayTarget: habit?.sortedDayTargets.first, weekGoal: habit?.sortedWeekGoals.first,
                                  weekResult: 4,
                                  progress: [
                                    .completed(completed: 3, target: 3),
                                    .completed(completed: 2, target: 2),
                                    .completed(completed: 2, target: 2),
                                    .partial(completed: 1, target: 2),
                                    .none(target: 6),
                                    .completed(completed: 6, target: 4),
                                    .none(target: Int(habit?.sortedDayTargets.first?.count ?? 4))
                                  ])
  return StatisticsWeekHabitChartView(results: results, color: habit?.color)
    .environment(\.managedObjectContext, context)
}
