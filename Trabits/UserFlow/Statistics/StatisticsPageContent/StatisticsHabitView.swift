//
//  StatisticsHabitView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsHabitView<Results: StatisticsResults, Summary: View, Chart: View>: View {
  @ObservedObject var habit: Habit
  var results: Results
  // swiftlint:disable redundant_type_annotation
  var isGrouped: Bool = false
  // swiftlint:enable redundant_type_annotation

  @ViewBuilder var summary: () -> Summary
  @ViewBuilder var chart: () -> Chart

  var body: some View {
    let hasDetailsRow = (!isGrouped && habit.category != nil) ||
    (results.weekGoal?.count ?? 0) > 0 || (results.dayTarget?.count ?? 1) > 1
    let color = isGrouped ? habit.category?.color : habit.color

    return VStack {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          if habit.archivedAt != nil {
            HabitArchivedStatusView()
          }
          Text(habit.title ?? "")
            .padding(0)
            .accessibilityHidden(true)
          Spacer(minLength: 0)
          if hasDetailsRow {
            HabitDetailsRowView(
              category: isGrouped ? nil : habit.category,
              dayTarget: results.dayTarget,
              weekGoal: results.weekGoal
            )
          }
        }
        .accessibilityElement(children: .combine)
        Spacer()
        summary()
      }
      .padding(8)
      .fixedSize(horizontal: false, vertical: true)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(
            LinearGradient(
              colors: [Color(uiColor: color ?? .neutral10), Color(uiColor: .neutral5)],
              startPoint: UnitPoint(x: 0.0, y: 0.5),
              endPoint: UnitPoint(x: 1.0, y: 0.5)
            )
          )
      )
      chart()
        .padding(.top, 20)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(habit.title ?? "")
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  var habit: Habit?
  do {
    habit = try context.fetch(Habit.orderedHabitsFetchRequest()).first
  } catch {}

  return StatisticsHabitView(habit: habit!, results: StatisticsWeekResults()) {
    Text("Summary")
  } chart: {
    Text("Chart")
  }
  .environment(\.managedObjectContext, context)
}
