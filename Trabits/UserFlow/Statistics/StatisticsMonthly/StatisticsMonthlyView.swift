//
//  StatisticsMonthlyView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsMonthlyView: View {
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
  return StatisticsMonthlyView()
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
