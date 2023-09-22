//
//  TodayHabitListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 22/09/2023.
//

import UIKit

final class GradientLayerView: UIView {
  override class var layerClass: AnyClass {
    return CAGradientLayer.self
  }

  private var gradientLayer: CAGradientLayer {
    return self.layer as! CAGradientLayer
  }

  init(startColor: UIColor, endColor: UIColor) {
    self.startColor = startColor
    self.endColor = endColor
    super.init(frame: .zero)

    gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
    gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private var startColor: UIColor
  private var endColor: UIColor

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
      layoutIfNeeded()
    }
  }
}

class TodayHabitListCell: UICollectionViewListCell {
  private var habit: Habit?
  private var isCompleted: Bool = false
  private var completionAction: UIAction?

  func fill(habit: Habit, isCompleted: Bool, completionAction: UIAction) {
    self.habit = habit
    self.isCompleted = isCompleted
    self.completionAction = completionAction
    setNeedsUpdateConfiguration()
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    var newBackgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)
    newBackgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    let startColor = habit?.category?.color ?? .systemGray6
    let endColor = UIColor.systemGray6
    let gradientView = GradientLayerView(startColor: startColor, endColor: endColor)
    newBackgroundConfiguration.customView = gradientView
    newBackgroundConfiguration.cornerRadius = 8
    backgroundConfiguration = newBackgroundConfiguration

    var newContentConfiguration = defaultContentConfiguration().updated(for: state)
    newContentConfiguration.text = habit?.title ?? ""
    contentConfiguration = newContentConfiguration

    var buttonConfiguration = UIButton.Configuration.bordered()
    buttonConfiguration.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(scale: .small))
    buttonConfiguration.baseForegroundColor = isCompleted ? .contrastColor : .backgroundColor
    buttonConfiguration.baseBackgroundColor = isCompleted ? habit?.category?.color : .backgroundColor
    buttonConfiguration.background.strokeColor = .contrastColor
    buttonConfiguration.background.strokeWidth = 2
    buttonConfiguration.cornerStyle = .capsule
    buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    let button = UIButton(configuration: buttonConfiguration, primaryAction: completionAction)

    let accessoryConfiguration = UICellAccessory.CustomViewConfiguration(customView: button, placement: .trailing(displayed: .always))
    accessories = [
      .customView(configuration: accessoryConfiguration)
    ]
  }
}
