//
//  StatisticsMonthView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsMonthView: View {
  @EnvironmentObject var userDefaultsObserver: UserDefaultsObserver
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @ObservedObject var monthData: StatisticsMonthData
  
  var body: some View {
    ScrollViewReader { proxy in
      GeometryReader { geo in
        List {
          if userDefaultsObserver.isHabitGroupingOn {
            StatisticsMonthGroupedView(monthData: monthData, width: geo.size.width) {
              topView()
            }
          } else {
            StatisticsMonthPlainView(monthData: monthData, width: geo.size.width) {
              topView()
            }
          }
        }
        .environment(\.defaultMinListRowHeight, 0)
        .headerProminence(.increased)
        .scrollContentBackground(.hidden)
        .listRowSpacing(6)
        .listStyle(.grouped)
        .overlay {
          if monthData.habitsWithResults.isEmpty {
            EmptyStateWrapperView(message: "List is empty. Please create a new habit.", actionTitle: "Add Habit") {
              statisticsRouter.navigateToStructureTab()
            }
          }
        }
        .onChange(of: statisticsRouter.currentState.date) { _ in
          proxy.scrollTo("top", anchor: .bottom)
        }
      }
    }
  }
  
  @ViewBuilder private func topView() -> some View {
    Rectangle()
      .frame(width: 0, height: 0)
      .listRowSeparator(.hidden)
      .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
      .id("top")
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  let monthInterval = Calendar.current.monthInterval(for: Date())!
  let monthData = StatisticsMonthData(month: monthInterval, context: context)!
  return StatisticsMonthView(monthData: monthData)
    .environment(\.managedObjectContext, context)
    .environmentObject(UserDefaultsObserver())
    .environmentObject(statisticsRouter)
}

