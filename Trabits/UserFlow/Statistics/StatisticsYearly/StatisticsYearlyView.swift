//
//  StatisticsYearlyView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsYearlyView: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  
  @State private var selectedTab = 0
  @State private var selectedDate = Date()
  
  var body: some View {
    Text("")
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  return StatisticsYearlyView()
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
