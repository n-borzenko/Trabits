//
//  StatisticsAnnualyView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsAnnualyView: View {
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  
  @State private var selectedTab = 0
  @State private var selectedDate = Date()
  
  var body: some View {
    VStack {
      let dateString = "\(Calendar.current.component(.year, from: statisticsRouter.currentDate))"
        
      StatisticsSubtitleView(
          unit: .annualy,
          subtitle: dateString,
          previousSelectionHandler: {
            guard let startOfThePreviousYear = Calendar.current.date(byAdding: .year, value: -1, to: selectedDate) else {
              return
            }
            selectedDate = startOfThePreviousYear
            withAnimation {
              selectedTab = -1
            }
          }, nextSelectionHandler: {
            guard let startOfTheNextYear = Calendar.current.date(byAdding: .year, value: 1, to: selectedDate) else {
              return
            }
            selectedDate = startOfTheNextYear
            withAnimation {
              selectedTab = 1
            }
          }
        )
      
      TabView(selection: $selectedTab) {
        if let previousDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedDate) {
          StatisticsYearView(startDate: previousDate)
            .tag(-1)
        }
        StatisticsYearView(startDate: selectedDate)
          .tag(0)
          .onDisappear {
            guard statisticsRouter.selectedContentType == .annualy else { return }
            if selectedTab != 0 && statisticsRouter.currentDate == selectedDate,
               let currentDate = Calendar.current.date(byAdding: .year, value: selectedTab, to: statisticsRouter.currentDate) {
              selectedDate = currentDate
            }
            selectedTab = 0
            statisticsRouter.currentDate = selectedDate
          }
        if let nextDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedDate) {
          StatisticsYearView(startDate: nextDate)
            .tag(1)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .disabled(selectedTab != 0)
    }
    .onChange(of: statisticsRouter.currentDate) { newDate in
      guard statisticsRouter.selectedContentType == .monthly else { return }
      guard let startOfTheYear = Calendar.current.startOfTheYear(for: newDate),
            selectedDate != startOfTheYear else { return }
      selectedDate = startOfTheYear
      statisticsRouter.currentDate = startOfTheYear
    }
    .onAppear {
      guard let startOfTheYear = Calendar.current.startOfTheYear(for: statisticsRouter.currentDate) else { return }
      selectedDate = startOfTheYear
      statisticsRouter.currentDate = startOfTheYear
    }
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  return StatisticsAnnualyView()
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
