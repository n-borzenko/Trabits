//
//  StatisticsWeekSummaryRowView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/02/2024.
//

import SwiftUI

struct StatisticsWeekSummaryRowView<Title: View, Chart: View, Goal: View>: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  @ViewBuilder var title: () -> Title
  @ViewBuilder var chart: () -> Chart
  @ViewBuilder var goal: () -> Goal

  var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
      GridRow {
        title()
          .gridCellColumns(2)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      GridRow {
        chart()
          .gridColumnAlignment(.leading)
        goal()
          .gridColumnAlignment(.trailing)
      }
      Divider()
    } else {
      GridRow {
        title()
          .gridColumnAlignment(.leading)
        chart()
          .gridColumnAlignment(.trailing)
        goal()
          .gridColumnAlignment(.trailing)
      }
      Divider()
    }
  }
}
