//
//  StatisticsSubtitleView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsSubtitleView: View {
  var unit: StatisticsContentType
  var subtitle: String
  var previousSelectionHandler: () -> Void
  var nextSelectionHandler: () -> Void
  
  var body: some View {
    HStack {
      Button {
        previousSelectionHandler()
      } label: {
        Image(systemName: "chevron.left")
      }
      .accessibilityLabel("Previous \(unit.itemTitle)")
      .accessibilityShowsLargeContentViewer {
        Label("Previous \(unit.itemTitle)", systemImage: "chevron.left")
      }
      
      Spacer()
      Text(subtitle)
        .accessibilityShowsLargeContentViewer()
      Spacer()
      
      Button {
        nextSelectionHandler()
      } label: {
        Image(systemName: "chevron.right")
      }
      .accessibilityLabel("Next \(unit.itemTitle)")
      .accessibilityShowsLargeContentViewer {
        Label("Next \(unit.itemTitle)", systemImage: "chevron.right")
      }
    }
    .font(.headline)
    .dynamicTypeSize(DynamicTypeSize.large...DynamicTypeSize.xxLarge)
    .padding(.horizontal)
  }
}

#Preview {
  StatisticsSubtitleView(unit: .weekly, subtitle: "Subtitle", previousSelectionHandler: { }, nextSelectionHandler: { })
}
