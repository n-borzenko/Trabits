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
    VStack {
      let dateString = Calendar.current.monthSymbols[Calendar.current.component(.month, from: statisticsRouter.currentDate) - 1]
        
      StatisticsSubtitleView(
          unit: .monthly,
          subtitle: dateString,
          previousSelectionHandler: {
            guard let startOfThePreviousMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) else {
              return
            }
            selectedDate = startOfThePreviousMonth
            withAnimation {
              selectedTab = -1
            }
          }, nextSelectionHandler: {
            guard let startOfTheNextMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) else {
              return
            }
            selectedDate = startOfTheNextMonth
            withAnimation {
              selectedTab = 1
            }
          }
        )
      
      TabView(selection: $selectedTab) {
        if let previousDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
          StatisticsMonthView(startDate: previousDate)
            .tag(-1)
        }
        StatisticsMonthView(startDate: selectedDate)
          .tag(0)
          .onDisappear {
            guard statisticsRouter.selectedContentType == .monthly else { return }
            if selectedTab != 0 && statisticsRouter.currentDate == selectedDate,
               let currentDate = Calendar.current.date(byAdding: .month, value: selectedTab, to: statisticsRouter.currentDate) {
              selectedDate = currentDate
            }
            selectedTab = 0
            statisticsRouter.currentDate = selectedDate
          }
        if let nextDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
          StatisticsMonthView(startDate: nextDate)
            .tag(1)
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .disabled(selectedTab != 0)
    }
    .onChange(of: statisticsRouter.currentDate) { newDate in
      guard statisticsRouter.selectedContentType == .monthly else { return }
      guard let startOfTheMonth = Calendar.current.startOfTheMonth(for: newDate),
            selectedDate != startOfTheMonth else { return }
      selectedDate = startOfTheMonth
      statisticsRouter.currentDate = startOfTheMonth
    }
    .onAppear {
      guard let startOfTheMonth = Calendar.current.startOfTheMonth(for: statisticsRouter.currentDate) else { return }
      selectedDate = startOfTheMonth
      statisticsRouter.currentDate = startOfTheMonth
    }
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  return StatisticsMonthlyView()
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
