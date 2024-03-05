//
//  StatisticsMonthHabitProgressView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 25/02/2024.
//

import SwiftUI

struct StatisticsMonthHabitProgressView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var monthLength: Int
  var monthResult: Int
  var color: UIColor?

  var body: some View {
    let width = dynamicTypeSize.isAccessibilitySize ? 100.0 : 60
    let progressWidth = Double(monthResult) / Double(monthLength) * width
    let height = dynamicTypeSize.isAccessibilitySize ? 20.0 : 10.0
    let borderWidth = dynamicTypeSize.isAccessibilitySize ? 2.0 : 1.0

    return VStack {
      Text("\(monthResult) of \(monthLength)")
        .font(.caption2)
        .padding(0)
      ZStack(alignment: .leading) {
        Capsule(style: .circular)
          .fill(Color(uiColor: .systemBackground))
        if progressWidth < height {
          if progressWidth > 0 {
            shortPath(height: height, progressWidth: progressWidth)
              .fill(Color(uiColor: color ?? .neutral10))
            shortPath(height: height, progressWidth: progressWidth)
              .stroke(Color.contrast, lineWidth: borderWidth)
          }
        } else {
          Capsule(style: .circular)
            .fill(Color(uiColor: color ?? .neutral10))
            .frame(width: progressWidth)
          Capsule(style: .circular)
            .stroke(Color.contrast, lineWidth: borderWidth)
            .frame(width: progressWidth)
        }
      }
      .frame(width: width, height: height)
    }
    .frame(maxWidth: width)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(monthResult) of \(monthLength) targets completed this month")
  }

  @ViewBuilder private func shortPath(height: Double, progressWidth: Double) -> some Shape {
    Path { path in
      let cornerRadius = height / 2
      let updatedProgressWidth = max(progressWidth, cornerRadius * 0.7)
      let angle = updatedProgressWidth * 90 / height
      let offset = cornerRadius * cos(angle * Double.pi / 180)

      path.addArc(
        center: CGPoint(x: cornerRadius - 2 * offset, y: cornerRadius),
        radius: cornerRadius,
        startAngle: Angle(degrees: -angle),
        endAngle: Angle(degrees: angle),
        clockwise: false
      )
      path.addArc(
        center: CGPoint(x: cornerRadius, y: cornerRadius),
        radius: cornerRadius, startAngle: Angle(degrees: 180 - angle),
        endAngle: Angle(degrees: 180 + angle),
        clockwise: false
      )
      path.closeSubpath()
    }
  }
}

#Preview {
  StatisticsMonthHabitProgressView(monthLength: 30, monthResult: 15)
}
