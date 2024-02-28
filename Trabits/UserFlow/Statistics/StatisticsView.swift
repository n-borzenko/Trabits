//
//  StatisticsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 01/02/2024.
//

import SwiftUI

struct StatisticsView: View {
  @Environment(\.managedObjectContext) var context
  @EnvironmentObject var statisticsRouter: StatisticsRouter
  @StateObject private var userDefaultsObserver = UserDefaultsObserver()
  @State private var isDatePickerVisible = false
  
  var body: some View {
    NavigationStack {
      VStack {
        Picker("Type of content", selection: $statisticsRouter.pickerContentType) {
          ForEach(StatisticsContentType.allCases, id: \.rawValue) { contentType in
            Text(contentType.rawValue)
              .tag(contentType)
          }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.bottom)
        .onChange(of: statisticsRouter.pickerContentType) { newValue in
          statisticsRouter.currentState = StatisticsRouterState(contentType: newValue, date: Date())
        }
        
        StatisticsPaginationViewControllerWrapper()
          .environmentObject(userDefaultsObserver)
      }
      .background(Color(uiColor: .systemBackground))
      .navigationTitle("Statistics")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          Button(
            userDefaultsObserver.isHabitGroupingOn ? "Hide category groups" : "Group by category",
            systemImage: userDefaultsObserver.isHabitGroupingOn ? "folder.fill" : "folder"
          ) {
            UserDefaults.standard.isHabitGroupingOn = !userDefaultsObserver.isHabitGroupingOn
          }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Choose date", systemImage: "calendar") {
            isDatePickerVisible = true
          }
        }
      }
      .sheet(isPresented: $isDatePickerVisible) {
        DatePickerView(selectedDate: statisticsRouter.currentState.date, delegate: statisticsRouter)
          .presentationDetents([.medium, .large])
          .presentationDragIndicator(.hidden)
          .interactiveDismissDisabled(true)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
    }
  }
}

#Preview {
  let statisticsRouter = StatisticsRouter()
  let context = PersistenceController.preview.container.viewContext
  return StatisticsView()
    .environment(\.managedObjectContext, context)
    .environmentObject(statisticsRouter)
}
