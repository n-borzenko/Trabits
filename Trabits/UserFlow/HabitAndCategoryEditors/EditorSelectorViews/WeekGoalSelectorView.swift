//
//  WeekGoalSelectorView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 03/12/2023.
//

import SwiftUI

struct WeekGoalSelectorView: View {
  @Binding var weekGoal: Int
  @Binding var resetIsOn: Bool
  @State private var isAlertPresented = false
  var isNew: Bool
  
  var body: some View {
    Section("Completed days per week") {
      Picker("Week goal", selection: $weekGoal) {
        Text("None").tag(0)
        ForEach(1...7, id: \.self) { item in
          Text("\(item)")
        }
      }
      if !isNew {
        HStack {
          Toggle("Reset previously set goals", isOn: $resetIsOn)
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
            "Resetting week goal",
            isPresented: $isAlertPresented,
            actions: { Button("OK", role: .cancel, action: { }) }
          ) {
            Text("Resetting previuosly set goals will affect your statistics.\nAlternatively, you can track new goal starting today.")
          }
        }
      }
    }
  }
}

#Preview {
  List {
    WeekGoalSelectorView(weekGoal: .constant(5), resetIsOn: .constant(false), isNew: false)
  }
}
