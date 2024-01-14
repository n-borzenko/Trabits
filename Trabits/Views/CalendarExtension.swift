//
//  CalendarExtension.swift
//  Trabits
//
//  Created by Natalia Borzenko on 10/01/2024.
//

import Foundation

extension Calendar {
  func startOfTheWeek(for date: Date) -> Date? {
    let dateComponents = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
    guard let startOfTheWeek = self.date(from: dateComponents) else { return nil }
    return startOfDay(for: startOfTheWeek)
  }
  
  func weekInterval(for date: Date) -> DateInterval? {
    return dateInterval(of: .weekOfYear, for: date)
  }
}
