//
//  CategoryListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit

class CategoryListCell: UICollectionViewListCell {
  private var category: Category?

  public func updateContent(with category: Category) {
    self.category = category
    var newContentConfiguration = defaultContentConfiguration()
    newContentConfiguration.text = "\(category.orderPriority): \(category.title!)"
    contentConfiguration = newContentConfiguration
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)

    //      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    //      backgroundConfiguration.backgroundColor = colors[indexPath.section].withAlphaComponent(0.3)
    //      backgroundConfiguration.strokeColor = colors[indexPath.section]
    //      backgroundConfiguration.strokeWidth = 2
    //      backgroundConfiguration.cornerRadius = 16
    //      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    //      cell.backgroundConfiguration = backgroundConfiguration

    backgroundConfiguration.backgroundColor = category?.color?.withAlphaComponent(0.6) ?? .white

    if state.isHighlighted {
      backgroundConfiguration.backgroundColor = .orange
    }

    if state.isSelected {
      backgroundConfiguration.backgroundColor = .brown
    }

    if state.cellDropState == .targeted {
      backgroundConfiguration.backgroundColor = .red
    }

    if state.cellDragState == .lifting {
      backgroundConfiguration.backgroundColor = .purple
    }

    self.backgroundConfiguration = backgroundConfiguration
  }
}
