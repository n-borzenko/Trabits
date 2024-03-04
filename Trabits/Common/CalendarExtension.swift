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

  // get universal 1-based weekday index from 0-based index of the day
  // return value can be used to obtain weekday symbols
  func weekdayIndex(_ index: Int) -> Int {
    (index + Calendar.current.firstWeekday - 1) % 7
  }

  // get 0-based index of the day from universal 1-based weekday index
  // return value represents index in the week on the view
  func viewWeekdayIndex(_ date: Date) -> Int {
    let weekdayIndex = component(.weekday, from: date)
    return (weekdayIndex + 7 - Calendar.current.firstWeekday) % 7
  }
}
