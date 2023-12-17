//
//  ColorSelectorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 03/12/2023.
//

import SwiftUI

struct ColorSelectorView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Binding var colorIndex: Int
  
  var body: some View {
    Section("Color") {
      ScrollView(.horizontal) {
        ScrollViewReader { proxy in
          HStack {
            ForEach(Array(PastelPalette.colors.enumerated()), id: \.offset) { index, color in
              Button(action: {
                colorIndex = index
              }) {
                ZStack {
                  Circle()
                    .fill(Color(uiColor: color))
                  Circle()
                    .stroke(
                      Color(.contrast),
                      lineWidth: dynamicTypeSize >= .accessibility1 ? 3 : 2
                    )
                    .padding(dynamicTypeSize >= .accessibility1 ? 1.5 : 1)
                  
                  if colorIndex == index {
                    Image(systemName: "checkmark")
                      .resizable()
                      .scaledToFit()
                      .padding(dynamicTypeSize >= .accessibility1 ? 20 : 12)
                  }
                }
              }
              .id(index)
              .accessibilityLabel(PastelPalette.colorTitles[index])
            }
          }
          .padding(.vertical)
          .onAppear {
            proxy.scrollTo(colorIndex)
          }
        }
      }
    }
  }
}


#Preview {
  List {
    ColorSelectorView(colorIndex: .constant(3))
  }
}
