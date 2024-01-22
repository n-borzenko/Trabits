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
          HStack(spacing: dynamicTypeSize >= .accessibility1 ? 8 : 4) {
            ForEach(Array(PastelPalette.colors.enumerated()), id: \.offset) { index, color in
              Button {
                colorIndex = index
              } label: {
                Image(systemName: "checkmark")
                  .font(.title2)
                  .imageScale(.medium)
                  .padding(dynamicTypeSize >= .accessibility1 ? 18 : 10)
                  .tint(colorIndex == index ? Color(.contrast) : .clear)
              }
              .background (
                ZStack {
                  Circle()
                    .fill(Color(uiColor: color))
                  Circle()
                    .stroke(
                      Color(.contrast),
                      lineWidth: dynamicTypeSize >= .accessibility1 ? 3 : 2
                    )
                }
              )
              .frame(minWidth: 44, minHeight: 44)
              .id(index)
            }
          }
          .padding(.vertical)
          .onAppear {
            proxy.scrollTo(colorIndex)
          }
          .accessibilityElement(children: .ignore)
          .accessibilityLabel("Item color")
          .accessibilityValue(PastelPalette.colorTitles[colorIndex])
          .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
              if colorIndex < PastelPalette.colors.count - 1  {
                colorIndex += 1
              } else {
                colorIndex = 0
              }
            case .decrement:
              if colorIndex > 0 {
                colorIndex -= 1
              } else {
                colorIndex = PastelPalette.colors.count - 1
              }
            @unknown default: return
            }
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
