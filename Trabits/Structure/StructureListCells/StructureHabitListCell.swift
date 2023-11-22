//
//  StructureHabitListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 10/11/2023.
//

import UIKit

class StructureHabitListCell: UICollectionViewListCell {
  var habit: Habit?
  var isSublevel: Bool = false
  
  override func updateConfiguration(using state: UICellConfigurationState) {
    super.updateConfiguration(using: state)
    var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
    backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: isSublevel ? 16 : 8, bottom: 4, trailing: 8)
    backgroundConfiguration.backgroundColor = habit?.category?.color?.withAlphaComponent(0.7) ?? .neutral5.withAlphaComponent(0.7)
    backgroundConfiguration.cornerRadius = 8

    if state.isHighlighted || state.isSelected {
      backgroundConfiguration.backgroundColor = habit?.category?.color?.withAlphaComponent(0.5) ?? .neutral5.withAlphaComponent(0.5)
    }

    self.backgroundConfiguration = backgroundConfiguration
    self.indentationLevel = isSublevel ? 1 : 0

    guard let habit = habit else { return }
    var contentConfiguration = self.defaultContentConfiguration().updated(for: state)
    contentConfiguration.text = habit.title
    self.contentConfiguration = contentConfiguration
  }
}
