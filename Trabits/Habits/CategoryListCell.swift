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
  private var category: Category?

  public func updateContent(with category: Category) {
    self.category = category

    let titlePublisher = category.publisher(for: \.title)
    let orderPublisher = category.publisher(for: \.order)
    titlePublisher.combineLatest(orderPublisher)
      .sink { [unowned self] (title, order) in
        var newContentConfiguration = self.defaultContentConfiguration()
        newContentConfiguration.text = "\(order): \(title)"
        self.contentConfiguration = newContentConfiguration
      }
      .store(in: &subscriptions)
  }

  override func prepareForReuse() {
    for subscription in subscriptions {
      subscription.cancel()
    }
    subscriptions.removeAll()
    super.prepareForReuse()
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
