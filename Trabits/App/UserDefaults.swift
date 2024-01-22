//
//  UserDefaults.swift
//  Trabits
//
//  Created by Natalia Borzenko on 28/12/2023.
//

import Foundation

extension UserDefaults {
  private static let isHabitGroupingOnKey = "me.nborzenko.Trabits.isHabitGroupingOn"
  private static let wasOnboardingShown = "me.nborzenko.Trabits.wasOnboardingShown"
  
  @objc dynamic var isHabitGroupingOn: Bool {
    get { bool(forKey: UserDefaults.isHabitGroupingOnKey) }
    set { setValue(newValue, forKey: UserDefaults.isHabitGroupingOnKey) }
  }
  
  @objc dynamic var wasOnboardingShown: Bool {
    get { bool(forKey: UserDefaults.wasOnboardingShown) }
    set { setValue(newValue, forKey: UserDefaults.wasOnboardingShown) }
  }
}
