//
//  StructureListItem.swift
//  Trabits
//
//  Created by Natalia Borzenko on 17/12/2023.
//

import SwiftUI

struct StructureListItem<Content: View>: View {
  var backgroundColor: UIColor?
  @ViewBuilder var content: () -> Content
  
  var body: some View {
    content()
    .listRowSeparator(.hidden)
    .listRowBackground(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(uiColor: backgroundColor ?? .neutral10).opacity(0.7))
        .padding(.horizontal, 12)
    )
    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
  }
}
