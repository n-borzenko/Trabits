//
//  StructureCategoryHeaderListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 14/11/2023.
//

import UIKit

class StructureCategoryHeaderListCell: UICollectionViewListCell {
  var category: Category?

  override func updateConfiguration(using state: UICellConfigurationState) {
    super.updateConfiguration(using: state)
    var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
    backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    backgroundConfiguration.backgroundColor = category?.color ?? .systemGray6
    backgroundConfiguration.cornerRadius = 8
    
    if state.isHighlighted || state.isSelected {
      backgroundConfiguration.backgroundColor = category?.color?.withAlphaComponent(0.8) ?? .systemGray6.withAlphaComponent(0.8)
    }
    
    self.backgroundConfiguration = backgroundConfiguration
    
    guard let category = category else { return }
    var contentConfiguration = self.defaultContentConfiguration()
    contentConfiguration.text = category.title
    self.contentConfiguration = contentConfiguration
  }
}
