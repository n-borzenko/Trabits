//
//  StatisticsWeekView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsWeekView: View {
  @EnvironmentObject var userDefaultsObserver: UserDefaultsObserver
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @ObservedObject var weekData: StatisticsWeekData

  var body: some View {
    ScrollViewReader { proxy in
      List {
        Section {
          Rectangle()
            .frame(width: 0, height: 0)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .id("top")

          StatisticsListItem {
            StatisticsWeekAchievementsView(weekData: weekData)
          }
          .id("numbers")
        } header: {
          StatisticsWeekHeaderView(title: "Achievements")
        }
        .id("achievements")

        if userDefaultsObserver.isStatisticsSummaryPreferred {
          Section {
            StatisticsListItem {
              StatisticsWeekSummaryGridView(
                weekData: weekData,
                isGrouped: userDefaultsObserver.isHabitGroupingOn
              )
            }
            .id("grid")
          }
          .id("summary")
        } else {
          if userDefaultsObserver.isHabitGroupingOn {
            StatisticsWeekGroupedView(weekData: weekData)
          } else {
            StatisticsWeekPlainView(weekData: weekData)
          }
        }
      }
      .environment(\.defaultMinListRowHeight, 0)
      .headerProminence(.increased)
      .scrollContentBackground(.hidden)
      .listRowSpacing(6)
      .listStyle(.grouped)
      .overlay {
        if weekData.habitsWithResults.isEmpty {
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

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  let weekInterval = Calendar.current.weekInterval(for: Date())!
  return StatisticsWeekView(weekData: StatisticsWeekData(week: weekInterval, context: context))
    .environment(\.managedObjectContext, context)
    .environmentObject(UserDefaultsObserver())
    .environmentObject(statisticsRouter)
}
