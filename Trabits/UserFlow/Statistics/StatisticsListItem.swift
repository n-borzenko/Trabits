//
//  StatisticsListItem.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/02/2024.
//

import SwiftUI

struct StatisticsListItem<Content: View>: View {
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
  }
}
