//
//  DayTargetSelectorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 03/12/2023.
//

import SwiftUI

struct DayTargetStepperView: View {
  @Binding var value: Int
  
  private let minValue = 1
  private let maxValue = 100
  
  var body: some View {
    HStack(spacing: 8) {
      Button(action: { value = max(value - 1, minValue) }) {
        Image(systemName: "minus")
          .frame(maxHeight: .infinity)
      }
      .buttonStyle(.bordered)
      .disabled(value == minValue)
      Text("\(value)")
        .foregroundColor(.secondary)
      Button(action: { value = min(value + 1, maxValue) }) {
        Image(systemName: "plus")
          .frame(maxHeight: .infinity)
      }
      .buttonStyle(.bordered)
      .disabled(value == maxValue)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityValue("\(value)")
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        guard value < maxValue else { break }
        value = value + 1
      case .decrement:
        guard value > minValue else { break }
        value = value - 1
      @unknown default:
        break
      }
    }
  }
}

struct DayTargetSelectorView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @Binding var dayTarget: Int
  @Binding var resetIsOn: Bool
  @State private var isAlertPresented = false
  var isNew: Bool
  
  var body: some View {
    let layout = dynamicTypeSize < .accessibility1 ? AnyLayout(HStackLayout(alignment: .center)) : AnyLayout(VStackLayout(alignment: .leading))
    
    Section("Completions per day") {
      layout {
        Text("Day target")
        Spacer()
        DayTargetStepperView(value: $dayTarget)
      }
      .accessibilityElement(children: .combine)
      if !isNew {
        HStack {
          Toggle("Reset previously set targets", isOn: $resetIsOn)
            .tint(.neutral60)
          Divider()
          Button(action: {
            isAlertPresented = true
          }) {
            Image(systemName: "info.circle")
              .font(.title2)
          }
          .foregroundColor(.neutral60)
          .buttonStyle(.borderless)
          .alert(
            "Resetting day target",
            isPresented: $isAlertPresented,
            actions: { Button("OK", role: .cancel, action: { }) }
          ) {
            Text("Resetting previuosly set targets will affect your statistics.\nAlternatively, you can track new target starting today.")
          }
        }
      }
    }
  }
}

#Preview {
  List {
    DayTargetSelectorView(dayTarget: .constant(1), resetIsOn: .constant(true), isNew: false)
  }
}
