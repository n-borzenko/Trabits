//
//  HabitDetailsRowView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 08/12/2023.
//

import SwiftUI

struct WrappableHStack: Layout {
  var hSpacing: CGFloat = 12
  var vSpacing: CGFloat = 4

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let width = proposal.replacingUnspecifiedDimensions().width
    let result = CalculatedResult(
      width: width, subviews: subviews, proposal: proposal, hSpacing: hSpacing, vSpacing: vSpacing
    )
    return result.bounds.size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let width = proposal.replacingUnspecifiedDimensions().width
    let result = CalculatedResult(
      width: width,
      subviews: subviews,
      proposal: proposal,
      hSpacing: hSpacing,
      vSpacing: vSpacing
    )

    for row in result.rows {
      for index in row.range {
        let subview = subviews[index]
        let xValue = bounds.origin.x + row.offsets[index - row.range.lowerBound]
        let yValue = bounds.origin.y + row.frame.midY
        subview.place(at: CGPoint(x: xValue, y: yValue), anchor: .leading, proposal: proposal)
      }
    }
  }

  struct CalculatedResultRow {
    var range: Range<Int>
    var offsets: [CGFloat]
    var frame: CGRect
  }

  struct CalculatedResult {
    var bounds = CGRect.zero
    var rows: [CalculatedResultRow] = []

    init(width: CGFloat, subviews: Subviews, proposal: ProposedViewSize, hSpacing: CGFloat, vSpacing: CGFloat) {
      var currentRowHeight = 0.0
      var currentRowWidth = 0.0
      var rowStartIndex = 0
      var currentRowOffset = 0.0
      var currentOffsets: [CGFloat] = []

      for index in subviews.indices {
        let subview = subviews[index]
        let subviewSize = subview.sizeThatFits(proposal)
        if currentRowWidth + subviewSize.width > width {
          // subview doesn't fit in the current row
          let rect = CGRect(x: 0, y: currentRowOffset, width: currentRowWidth - hSpacing, height: currentRowHeight)
          let row = CalculatedResultRow(range: rowStartIndex..<index, offsets: currentOffsets, frame: rect)
          rows.append(row)
          bounds.size.width = max(bounds.width, row.frame.width)
          bounds.size.height += row.frame.height
          bounds.size.height += rowStartIndex == 0 ? 0 : vSpacing

          currentRowOffset += (currentRowHeight + vSpacing)
          currentRowHeight = 0.0
          currentRowWidth = 0.0
          rowStartIndex = index
          currentOffsets = []
        }

        // subview fits in the current row
        currentOffsets.append(currentRowWidth)
        // if subview is larger than container it will be truncated
        currentRowWidth += min(subviewSize.width, width)
        currentRowHeight = max(currentRowHeight, subviewSize.height)

        // last item has been just added
        if index == subviews.count - 1 {
          let rect = CGRect(x: 0, y: currentRowOffset, width: currentRowWidth, height: currentRowHeight)
          let row = CalculatedResultRow(range: rowStartIndex..<(index + 1), offsets: currentOffsets, frame: rect)

          rows.append(row)
          bounds.size.width = max(bounds.width, row.frame.width)
          bounds.size.height += row.frame.height
          bounds.size.height += rowStartIndex == 0 ? 0 : vSpacing
          break
        }

        currentRowWidth += hSpacing
      }
    }
  }
}

struct HabitDetailsRowView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var category: Category?
  var dayTarget: DayTarget?
  var weekGoal: WeekGoal?

  private struct DayTargetView: View {
    @ObservedObject var dayTarget: DayTarget

    var body: some View {
      if dayTarget.count > 1 {
        HStack(spacing: 2) {
          Image(systemName: "target")
          Text("\(dayTarget.count)/day")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day target is \(dayTarget.count) per day")
      }
    }
  }

  private struct WeekGoalView: View {
    @ObservedObject var weekGoal: WeekGoal

    var body: some View {
      // swiftlint:disable empty_count
      if weekGoal.count > 0 {
        // swiftlint:enable empty_count
        HStack(spacing: 2) {
          Image(systemName: "flame")
          Text("\(weekGoal.count)/week")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Week goal is \(weekGoal.count) per week")
      }
    }
  }

  var body: some View {
    WrappableHStack {
      if let category, let title = category.title, !title.isEmpty {
        Text(title)
          .font(.caption2)
          .padding(.horizontal, 4)
          .background(Color(uiColor: .systemBackground).opacity(0.6))
          .cornerRadius(4)
          .lineLimit(dynamicTypeSize >= .accessibility1 ? 2 : 1)
          .accessibilityLabel("Category \(title)")
      }

      HStack(spacing: 12) {
        if let dayTarget {
          DayTargetView(dayTarget: dayTarget)
        }
        if let weekGoal {
          WeekGoalView(weekGoal: weekGoal)
        }
      }
      .foregroundColor(.secondary)
      .font(.caption2)
    }
  }
}

struct HabitArchivedStatusView: View {
  var body: some View {
    Text("Archived")
      .font(.caption2)
      .padding(.horizontal, 4)
      .foregroundColor(Color(uiColor: .inverted))
      .background(Color(uiColor: .neutral80).opacity(0.8))
      .cornerRadius(4)
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var habit: Habit?
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}

  return HabitDetailsRowView(
    category: habit?.category,
    dayTarget: habit?.sortedDayTargets.first,
    weekGoal: habit?.sortedWeekGoals.first
  )
  .environment(\.managedObjectContext, context)
  .padding()
  .background(Color(uiColor: habit?.color ?? .neutral5))
}
