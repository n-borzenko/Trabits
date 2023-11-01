//
//  HabitListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit
import Combine

class HabitListCell: UICollectionViewListCell {
  private var subscriptions: Set<AnyCancellable> = []

  var habit: Habit? {
    didSet {
      guard let habit = habit else { return }
      habit.publisher(for: \.title)
        .sink { [unowned self] _ in
          self.setNeedsUpdateConfiguration()
        }
        .store(in: &subscriptions)
    }
  }

  override func prepareForReuse() {
    for subscription in subscriptions {
      subscription.cancel()
    }
    subscriptions.removeAll()
    super.prepareForReuse()
  }

  deinit {
    for subscription in subscriptions {
      subscription.cancel()
    }
    subscriptions.removeAll()
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    super.updateConfiguration(using: state)
    var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
    backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 8)
    backgroundConfiguration.backgroundColor = habit?.category?.color?.withAlphaComponent(0.7) ?? .systemGray6.withAlphaComponent(0.7)
    backgroundConfiguration.cornerRadius = 8

    if state.isHighlighted || state.isSelected {
      backgroundConfiguration.backgroundColor = habit?.category?.color?.withAlphaComponent(0.5) ?? .systemGray6.withAlphaComponent(0.5)
    }

    self.backgroundConfiguration = backgroundConfiguration
    indentationLevel = 1

    guard let habit = habit else { return }
    var contentConfiguration = self.defaultContentConfiguration().updated(for: state)
    contentConfiguration.text = habit.title
    self.contentConfiguration = contentConfiguration
    
    var reorderOptions = UICellAccessory.ReorderOptions()
    reorderOptions.showsVerticalSeparator = false
    accessories = [.delete(), .reorder(options: reorderOptions)]
  }
}
