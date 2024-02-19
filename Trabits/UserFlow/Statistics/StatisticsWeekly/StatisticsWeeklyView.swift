//
//  StatisticsWeeklyView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 01/02/2024.
//

import SwiftUI

struct StatisticsWeeklyView: View {
  @Environment(\.managedObjectContext) var context
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  
  @StateObject var weeklyStatistics = StatisticsWeeklyDataContainer()
  
  var body: some View {
    VStack {
      StatisticsSubtitleView(
        unit: .weekly,
        subtitle: getIntervalString(),
        previousSelectionHandler: {
          guard let date = weeklyStatistics.startDates.first else { return }
          withAnimation { weeklyStatistics.selectedDate = date }
        }, nextSelectionHandler: {
          guard let date = weeklyStatistics.startDates.last else { return }
          withAnimation { weeklyStatistics.selectedDate = date }
        }
      )
      
      TabView(selection: $weeklyStatistics.selectedDate) {
        ForEach(Array(weeklyStatistics.startDates.enumerated()), id: \.element) { index, date in
          if let weekData = weeklyStatistics.weeksData[date] {
            StatisticsWeekView(weekData: weekData)
              .tag(date)
              .onDisappear {
                guard statisticsRouter.selectedContentType == .weekly, index == 1 else { return }
                statisticsRouter.currentDate = weeklyStatistics.selectedDate
              }
          }
        }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .disabled(weeklyStatistics.startDates.count == 3 && weeklyStatistics.selectedDate != weeklyStatistics.startDates[1])
    }
    .onChange(of: statisticsRouter.currentDate) { newDate in
      guard statisticsRouter.selectedContentType == .weekly, weeklyStatistics.startDates.count == 3,
            Calendar.current.startOfTheWeek(for: statisticsRouter.currentDate) != weeklyStatistics.startDates[1] else { return }
      weeklyStatistics.recalculateData(newDate: newDate)
      statisticsRouter.currentDate = weeklyStatistics.startDates[1]
    }
    .onAppear {
      if weeklyStatistics.context == nil {
        weeklyStatistics.context = context
      }
      Task {
        await MainActor.run { [weak weeklyStatistics] in
          guard let weeklyStatistics else { return }
          weeklyStatistics.recalculateData(newDate: statisticsRouter.currentDate)
          statisticsRouter.currentDate = weeklyStatistics.startDates[1]
        }
      }
    }
  }
  
  private func getIntervalString() -> String {
    guard weeklyStatistics.startDates.count == 3,
          let interval = weeklyStatistics.weeksData[weeklyStatistics.startDates[1]]?.week,
          let endDate = Calendar.current.date(byAdding: .day, value: -1, to: interval.end) else { return "" }
    let startDateString = interval.start.formatted(date: .abbreviated, time: .omitted)
    let endDateString = endDate.formatted(date: .abbreviated, time: .omitted)
    return "\(startDateString) - \(endDateString)"
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  return StatisticsWeeklyView()
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
