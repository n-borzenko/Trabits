//
//  HabitListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 18/08/2023.
//

import UIKit
import Combine

class MyGradientView : UIView {
    override static var layerClass: AnyClass { CAGradientLayer.self }
}

class HabitListCell: UICollectionViewListCell {
  private var subscriptions: Set<AnyCancellable> = []
  private var habit: Habit?

  public func updateContent(with habit: Habit) {
    self.habit = habit

    habit.publisher(for: \.title)
      .sink { [unowned self] h in
        var newContentConfiguration = self.defaultContentConfiguration()
        newContentConfiguration.text = "\(h)"
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
    //      let view = MyGradientView()
    //      (view.layer as! CAGradientLayer).colors = [
    //        colors[indexPath.section].withAlphaComponent(0.5).cgColor,
    //        UIColor.lightGray.withAlphaComponent(0.5).cgColor
    //      ]
    //      (view.layer as! CAGradientLayer).startPoint = CGPoint(x: 0, y: 0.5)
    //      (view.layer as! CAGradientLayer).endPoint = CGPoint(x: 1, y: 0.5)
    //      backgroundConfiguration.customView = view
    //      backgroundConfiguration.backgroundColor = .purple.withAlphaComponent(0.2)
    //      backgroundConfiguration.cornerRadius = 16
    //      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    //      cell.backgroundConfiguration = backgroundConfiguration

    backgroundConfiguration.backgroundColor = habit?.category?.color?.withAlphaComponent(0.3) ?? .white

    if state.isHighlighted {
      backgroundConfiguration.backgroundColor = .orange
    }

    if state.isSelected {
      backgroundConfiguration.backgroundColor = .brown
    }

    if state.cellDragState == .lifting {
      backgroundConfiguration.backgroundColor = .purple
    }

    self.backgroundConfiguration = backgroundConfiguration
  }
}
