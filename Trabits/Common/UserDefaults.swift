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
    case isHabitGroupingOn = "me.nborzenko.Trabits.isHabitGroupingOn"
    case isStatisticsSummaryPreferred = "me.nborzenko.Trabits.isStatisticsSummaryPreferred"
    case wasOnboardingShown = "me.nborzenko.Trabits.wasOnboardingShown"
  }
  
  @objc dynamic var isHabitGroupingOn: Bool {
    get { bool(forKey: Key.isHabitGroupingOn.rawValue) }
    set { setValue(newValue, forKey: Key.isHabitGroupingOn.rawValue) }
  }
  
  @objc dynamic var isStatisticsSummaryPreferred: Bool {
    get { hasData(for: Key.isStatisticsSummaryPreferred) ? bool(forKey: Key.isStatisticsSummaryPreferred.rawValue) : true }
    set { setValue(newValue, forKey: Key.isStatisticsSummaryPreferred.rawValue) }
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
  @Published var isStatisticsSummaryPreferred = UserDefaults.standard.isStatisticsSummaryPreferred
  
  private var cancellables = Set<AnyCancellable>()
  
  init() {
    UserDefaults.standard
      .publisher(for: \.isHabitGroupingOn)
      .sink { [weak self] in
        self?.isHabitGroupingOn = $0
      }
      .store(in: &cancellables)
    
    UserDefaults.standard
      .publisher(for: \.isStatisticsSummaryPreferred)
      .sink { [weak self] in
        self?.isStatisticsSummaryPreferred = $0
      }
      .store(in: &cancellables)
  }
  
  deinit {
    cancellables.forEach { $0.cancel() }
    cancellables.removeAll()
  }
}
