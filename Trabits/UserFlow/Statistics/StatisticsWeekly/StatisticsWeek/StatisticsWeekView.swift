//
//  StatisticsWeekView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekView: View {
  @EnvironmentObject var userDefaultsObserver: UserDefaultsObserver
  @ObservedObject var weekData: StatisticsWeekData
  
  var body: some View {
    if userDefaultsObserver.isHabitGroupingOn {
      StatisticsWeekGroupedView(weekData: weekData)
    } else {
      StatisticsWeekPlainView(weekData: weekData)
    }
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  return StatisticsWeekView(weekData: StatisticsWeekData(week: weekInterval, context: context))
    .environment(\.managedObjectContext, context)
    .environmentObject(UserDefaultsObserver())
    .environmentObject(statisticsRouter)
}
