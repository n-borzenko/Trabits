//
//  StatisticsWeekAchievementsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 16/02/2024.
//

import SwiftUI

struct StatisticsWeekAchievementsView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @ObservedObject var weekData: StatisticsWeekData

  var body: some View {
    let summary = weekData.habitsWithResults.reduce(into: (targets: 0, goals: 0)) {
      $0.targets += $1.results.weekResult
      let weekGoal = $1.results.weekGoal?.count ?? 0
      $0.goals += weekGoal > 0 && $1.results.weekResult >= weekGoal ? 1 : 0
    }

    return HStack(spacing: 16) {
      Spacer(minLength: 0)
      itemView(imageName: "target") {
        Text("^[\(summary.targets) \("target")](inflect: true)")
      }
      itemView(imageName: "flame") {
        Text("^[\(summary.goals) \("goal")](inflect: true)")
      }
      Spacer(minLength: 0)
    }
    .accessibilityElement(children: .contain)
    .frame(maxWidth: .infinity)
  }

  @ViewBuilder private func itemView(imageName: String, @ViewBuilder text: @escaping () -> some View) -> some View {
    Group {
      if dynamicTypeSize.isAccessibilitySize {
        Label(title: text) {
          Image(systemName: imageName)
        }
      } else {
        HStack(spacing: 4) {
          Image(systemName: imageName)
            .accessibilityHidden(true)
          text()
        }
      }
    }
    .padding(8)
    .background(Color(uiColor: .neutral5).opacity(0.7))
    .cornerRadius(8)
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  return StatisticsWeekAchievementsView(weekData: StatisticsWeekData(week: weekInterval, context: context))
    .environment(\.managedObjectContext, context)
}
