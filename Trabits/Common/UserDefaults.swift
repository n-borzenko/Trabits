//
//  UserDefaults.swift
//  Trabits
//
//  Created by Natalia Borzenko on 28/12/2023.
//

import Foundation
import Combine

extension UserDefaults {
  enum Key: String {
    case isHabitGroupingOnKey = "me.nborzenko.Trabits.isHabitGroupingOn"
    case wasOnboardingShown = "me.nborzenko.Trabits.wasOnboardingShown"
  }
  
  @objc dynamic var isHabitGroupingOn: Bool {
    get { bool(forKey: Key.isHabitGroupingOnKey.rawValue) }
    set { setValue(newValue, forKey: Key.isHabitGroupingOnKey.rawValue) }
  }
  
  @objc dynamic var wasOnboardingShown: Bool {
    get { bool(forKey: Key.wasOnboardingShown.rawValue) }
    set { setValue(newValue, forKey: Key.wasOnboardingShown.rawValue) }
  }

  func removeData(for key: Key) {
    removeObject(forKey: key.rawValue)
  }
  
  func hasData(for key: Key) -> Bool {
    object(forKey: key.rawValue) != nil
  }
}

@MainActor
class UserDefaultsObserver: ObservableObject {
  @Published var isHabitGroupingOn = UserDefaults.standard.isHabitGroupingOn
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    UserDefaults.standard
      .publisher(for: \.isHabitGroupingOn)
      .sink { [weak self] in
        self?.isHabitGroupingOn = $0
      }
      .store(in: &cancellables)
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}
