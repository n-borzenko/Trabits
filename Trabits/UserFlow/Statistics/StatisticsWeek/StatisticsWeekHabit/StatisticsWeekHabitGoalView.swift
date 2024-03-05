//
//  StatisticsWeekHabitGoalView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 08/02/2024.
//

import SwiftUI

struct StatisticsWeekHabitGoalView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var weekGoal: Int
  var weekResult: Int
  var color: UIColor?

  var body: some View {
    let hasWeekGoal = weekGoal > 0
    let isWeekGoalAchieved = weekResult >= weekGoal
    let isSymbolVisible = hasWeekGoal && isWeekGoalAchieved

    return VStack(spacing: dynamicTypeSize.isAccessibilitySize ? 12.0 : 8.0) {
      Image(systemName: "flame")
        .font(.caption)
        .imageScale(.medium)
        .padding(dynamicTypeSize.isAccessibilitySize ? 8 : 4)
        .tint(Color(.contrast))
        .opacity(isSymbolVisible ? 1 : 0)
        .background(
          ZStack {
            Circle()
              .fill(Color(uiColor: isSymbolVisible ? color ?? .neutral10 : .systemBackground))
            Circle()
              .stroke(
                Color(.contrast),
                lineWidth: dynamicTypeSize.isAccessibilitySize ? 2 : 1
              )
          }
        )
      Text("\(weekResult)\(hasWeekGoal ? "/\(weekGoal)" : "")")
        .font(.caption2)
        .padding(0)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      hasWeekGoal ?
      "\(weekResult) of \(weekGoal) targets completed this week , goal \(isWeekGoalAchieved ? "" : "not " )achieved" :
        "\(weekResult) targets completed this week"
    )
  }
}

#Preview {
  StatisticsWeekHabitGoalView(weekGoal: 2, weekResult: 3)
}
