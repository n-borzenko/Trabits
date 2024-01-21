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
  
  func generateSelectedDateDescription() -> String {
    let dateTitle = dateFormatter.string(from: selectedDate)
    let isToday = Calendar.current.isDateInToday(selectedDate)    
    return "\(dateTitle) \(isToday ? ", Today" : "")"
  }
}
