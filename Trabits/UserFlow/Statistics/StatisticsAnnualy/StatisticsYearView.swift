//
//  StatisticsYearView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 02/02/2024.
//

import SwiftUI

struct StatisticsYearView: View {
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
  return StatisticsYearView(startDate: Calendar.current.startOfTheYear(for: Date())!)
    .environment(\.managedObjectContext, context)
}
