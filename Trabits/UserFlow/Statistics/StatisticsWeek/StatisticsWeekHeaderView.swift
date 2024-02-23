//
//  StatisticsWeekHeaderView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 22/02/2024.
//

import SwiftUI

struct StatisticsWeekHeaderView: View {
  @EnvironmentObject var userDefaultsObserver: UserDefaultsObserver
  var title: String
  
  var body: some View {
    let label = UserDefaults.standard.isStatisticsSummaryPreferred ? "Show detailed charts" : "Show summary"
    let imageName = "rectangle.arrowtriangle.2.\(UserDefaults.standard.isStatisticsSummaryPreferred ? "outward" : "inward")"
    
    return HStack(alignment: .center) {
      Text(title)
      Spacer()
      Button {
        UserDefaults.standard.isStatisticsSummaryPreferred = !userDefaultsObserver.isStatisticsSummaryPreferred
      } label: {
        Image(systemName: imageName)
      }
      .accessibilityLabel(label)
      .accessibilityShowsLargeContentViewer {
        Label(label, systemImage: imageName)
      }
      .font(.headline)
      .dynamicTypeSize(DynamicTypeSize.large...DynamicTypeSize.xxxLarge)
    }
  }
}

#Preview {
    StatisticsWeekHeaderView(title: "Summary")
    .environmentObject(UserDefaultsObserver())
}
