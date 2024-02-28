//
//  StatisticsHabitSmallWeekGoalView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 17/02/2024.
//

import SwiftUI

struct StatisticsHabitSmallWeekGoalView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  
  var weekGoal: Int
  var weekResult: Int
  var color: UIColor?
  
  var body: some View {
    let hasWeekGoal = weekGoal > 0
    let isWeekGoalAchieved = weekResult >= weekGoal
    let isSymbolVisible = hasWeekGoal && isWeekGoalAchieved
    
    return HStack {
      Text(hasWeekGoal ? "\(weekResult)/\(weekGoal)" : "\(weekResult)")
        .font(.caption2)
        .padding(0)
      Image(systemName: "flame")
        .font(.caption)
        .imageScale(.medium)
        .padding(dynamicTypeSize.isAccessibilitySize ? 8 : 4)
        .tint(Color(.contrast))
        .opacity(isSymbolVisible ? 1 : 0)
        .background (
          ZStack {
            Circle()
              .fill(Color(uiColor: isSymbolVisible ? color ?? .neutral10 : .white))
            Circle()
              .stroke(
                Color(.contrast),
                lineWidth: dynamicTypeSize.isAccessibilitySize ? 2 : 1
              )
          }
            .opacity(hasWeekGoal ? 1 : 0)
        )
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      hasWeekGoal ? "\(weekResult) of \(weekGoal) targets completed this week, goal \(isWeekGoalAchieved ? "" : "not " )achieved" :
        "\(weekResult) targets completed this week"
    )
    .accessibilityAddTraits(.isStaticText)
    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    .accessibilityShowsLargeContentViewer()
  }
}

#Preview {
  StatisticsHabitSmallWeekGoalView(weekGoal: 2, weekResult: 3)
}
