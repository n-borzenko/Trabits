//
//  StatisticsMonthView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsMonthView: View {
  var startDate: Date
  
  var body: some View {
    HStack {
      Spacer()
      Text("\(startDate.formatted(date: .abbreviated, time: .omitted))")
      Spacer()
    }
  }
}

#Preview {
  let context = PersistenceController.preview.container.viewContext
  return StatisticsMonthView(startDate: Calendar.current.startOfTheMonth(for: Date())!)
    .environment(\.managedObjectContext, context)
}
