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
  
  func startOfTheMonth(for date: Date) -> Date? {
    let dateComponents = dateComponents([.month, .year], from: date)
    guard let startOfTheMonth = self.date(from: dateComponents) else { return nil }
    return startOfDay(for: startOfTheMonth)
  }
  
  func startOfTheYear(for date: Date) -> Date? {
    let dateComponents = dateComponents([.year], from: date)
    guard let startOfTheYear = self.date(from: dateComponents) else { return nil }
    return startOfDay(for: startOfTheYear)
  }
  
  func weekInterval(for date: Date, adjustment: Int = 0) -> DateInterval? {
    guard let adjustedDate = self.date(byAdding: .day, value: 7 * adjustment, to: date) else { return nil }
    return dateInterval(of: .weekOfYear, for: adjustedDate)
  }
  
  func monthInterval(for date: Date, adjustment: Int = 0) -> DateInterval? {
    guard let adjustedDate = self.date(byAdding: .month, value: 1 * adjustment, to: date) else { return nil }
    return dateInterval(of: .month, for: adjustedDate)
  }
}
