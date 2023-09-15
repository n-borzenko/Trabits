//
//  CategoryListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit
import Combine

class CategoryListCell: UICollectionViewListCell {
  private var subscriptions: Set<AnyCancellable> = []
  var category: Category? {
    didSet {
      guard let category = category else { return }
      category.publisher(for: \.title)
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
    backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    backgroundConfiguration.backgroundColor = category?.color ?? .systemGray6
    backgroundConfiguration.cornerRadius = 8

    if state.isHighlighted || state.isSelected {
      backgroundConfiguration.backgroundColor = category?.color?.withAlphaComponent(0.8) ?? .systemGray6.withAlphaComponent(0.8)
    }

    if state.cellDropState == .targeted {
      backgroundConfiguration.strokeColor = .contrastColor
      backgroundConfiguration.strokeWidth = 3
    }

    if state.cellDragState == .lifting {
      backgroundConfiguration.strokeColor = .contrastColor
      backgroundConfiguration.strokeWidth = 1
    }

    self.backgroundConfiguration = backgroundConfiguration
    indentationLevel = 0

    guard let category = category else { return }
    var contentConfiguration = self.defaultContentConfiguration()
    contentConfiguration.text = category.title
    contentConfiguration.secondaryText = "\(category.habits?.count ?? 0)"
    contentConfiguration.prefersSideBySideTextAndSecondaryText = true
    self.contentConfiguration = contentConfiguration

    var options = UICellAccessory.OutlineDisclosureOptions(style: .header)
    options.tintColor = .contrastColor
    options.isHidden = (category.habits?.count ?? 0) == 0
    accessories = [.outlineDisclosure(options: options)]
  }
}
