//
//  CategoryListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit
//import Combine

class CategoryListCell: UICollectionViewListCell {
//  private var subscriptions: Set<AnyCancellable> = []
  var category: Category?
//  {
//    didSet {
//      guard let category = category else { return }
//      category.publisher(for: \.title)
//        .sink { [unowned self] _ in
//          self.setNeedsUpdateConfiguration()
//        }
//        .store(in: &subscriptions)
//    }
//  }

//  override func prepareForReuse() {
//    for subscription in subscriptions {
//      subscription.cancel()
//    }
//    subscriptions.removeAll()
//    super.prepareForReuse()
//  }
//
//  deinit {
//    for subscription in subscriptions {
//      subscription.cancel()
//    }
//    subscriptions.removeAll()
//  }

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
      backgroundConfiguration.strokeColor = .contrast
      backgroundConfiguration.strokeWidth = 1
    }
    
    self.backgroundConfiguration = backgroundConfiguration
    indentationLevel = 0
    
    guard let category = category else { return }
    let habitsCount = category.habits?.count ?? 0
    var contentConfiguration = self.defaultContentConfiguration()
    contentConfiguration.text = category.title
    contentConfiguration.secondaryText = "\(habitsCount) habit\(habitsCount != 1 ? "s" : "")"
    contentConfiguration.secondaryTextProperties.color = .secondaryLabel
    contentConfiguration.prefersSideBySideTextAndSecondaryText = false
    self.contentConfiguration = contentConfiguration
    
    var outlineDisclosureOptions = UICellAccessory.OutlineDisclosureOptions()
    outlineDisclosureOptions.style = .header
    outlineDisclosureOptions.tintColor = .neutral80
    outlineDisclosureOptions.isHidden = habitsCount == 0
    
    var reorderOptions = UICellAccessory.ReorderOptions()
    reorderOptions.showsVerticalSeparator = false
    
    accessories = [.outlineDisclosure(options: outlineDisclosureOptions), .delete(), .reorder(options: reorderOptions)]
  }
}
