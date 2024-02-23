//
//  StatisticsWeekSummaryChartView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/02/2024.
//

import SwiftUI

struct StatisticsWeekSummaryChartView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  var results: StatisticsResults
  var color: UIColor?
  
  var body: some View {
    HStack(spacing: dynamicTypeSize.isAccessibilitySize ? 6 : 4) {
      ForEach(Array(results.progress.enumerated()), id: \.offset) { index, result in
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(getDescription(result: result, index: index))
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityAddTraits(.isStaticText)
  }
  
  private func getProperties(result: StatisticsResults.DayProgress) -> (hasBorder: Bool, hasDot: Bool) {
    switch result {
    case .completed(completed: _, target: _): return (hasBorder: true, hasDot: true)
    case .partial(completed: _, target: _): return (hasBorder: true, hasDot: false)
    case .none(target: _): return (hasBorder: false, hasDot: false)
    }
  }
  
  private func getDescription(result: StatisticsResults.DayProgress, index: Int) -> String {
    let weekdayIndex = (index + Calendar.current.firstWeekday - 1) % 7
    return "\(result.message) on \(Calendar.current.standaloneWeekdaySymbols[weekdayIndex])"
  }
}
