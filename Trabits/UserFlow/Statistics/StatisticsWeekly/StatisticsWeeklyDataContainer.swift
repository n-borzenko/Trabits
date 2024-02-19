//
//  StatisticsWeeklyDataContainer.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/02/2024.
//

import Foundation
import CoreData

class StatisticsWeeklyDataContainer: ObservableObject {
  @Published var startDates: [Date] = []
  
  @Published var weeksData: [Date: StatisticsWeekData] = [:]
  
  @Published var selectedDate = Date()
  
  var context: NSManagedObjectContext?
  
  func recalculateData(newDate: Date) {
    guard let context, let updatedDate = Calendar.current.startOfTheWeek(for: newDate) else { return }
    let intervals = [-1, 0, 1].compactMap { Calendar.current.weekInterval(for: updatedDate, adjustment: $0) }
    startDates = intervals.map { $0.start }
    
    for key in weeksData.keys {
      guard startDates.firstIndex(of: key) == nil else { continue }
      weeksData.removeValue(forKey: key)
    }
    
    for interval in intervals {
      guard weeksData[interval.start] == nil else { continue }
      weeksData[interval.start] = StatisticsWeekData(week: interval, context: context)
    }
    selectedDate = startDates[1]
  }
}
