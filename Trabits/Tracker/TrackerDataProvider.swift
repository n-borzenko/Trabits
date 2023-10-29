//
//  TrackerDataProvider.swift
//  Trabits
//
//  Created by Natalia Borzenko on 28/09/2023.
//

import Foundation

class TrackerDataProvider: ObservableObject {
  @Published var selectedDate: Date
  
  private let dateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .none
    dateFormatter.dateStyle = .full
    return dateFormatter
  }()
  
  init() {
    selectedDate = Calendar.current.startOfDay(for: Date())
  }
  
  func getStartOfTheWeek(for date: Date) -> Date? {
    let dateComponents = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    guard let startOfTheWeek = Calendar.current.date(from: dateComponents) else { return nil }
    return Calendar.current.startOfDay(for: startOfTheWeek)
  }
  
  func generateSelectedDateDescription() -> String {
    let dateTitle = dateFormatter.string(from: selectedDate)
    let isToday = Calendar.current.isDateInToday(selectedDate)    
    return "\(dateTitle) \(isToday ? ", Today" : "")"
  }
}
