//
//  StatisticsWeekSummaryHeaderView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 16/02/2024.
//

import SwiftUI

struct StatisticsWeekSummaryHeaderView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @ObservedObject var weekData: StatisticsWeekData
  
  var body: some View {
    let summary = weekData.habitsWithResults.reduce(into: (targets: 0, goals: 0)) {
      $0.targets += $1.results.weekResult
      let weekGoal = $1.results.weekGoal?.count ?? 0
      $0.goals += weekGoal > 0 && $1.results.weekResult >= weekGoal ? 1 : 0
    }
    
    let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
    
    return layout {
      Spacer(minLength: 0)
      HStack(spacing: 4) {
        Image(systemName: "target")
        Text("^[\(summary.targets) \("target")](inflect: true) completed")
      }
      .padding(8)
      .background(Color(uiColor: .neutral5).opacity(0.7))
      .cornerRadius(8)
      HStack(spacing: 4) {
        Image(systemName: "flame")
        Text("^[\(summary.goals) \("goal")](inflect: true) achieved")
      }
      .padding(8)
      .background(Color(uiColor: .neutral5).opacity(0.7))
      .cornerRadius(8)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity)
    .padding(.bottom)
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  return StatisticsWeekSummaryHeaderView(weekData: StatisticsWeekData(week: weekInterval, context: context))
    .environment(\.managedObjectContext, context)
}
