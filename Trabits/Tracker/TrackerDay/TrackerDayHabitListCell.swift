//
//  TrackerDayHabitListCell.swift
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

  init(startColor: UIColor = .clear, endColor: UIColor = .clear) {
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
  
  func updateColors(startColor: UIColor, endColor: UIColor) {
    self.startColor = startColor
    self.endColor = endColor
    gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    layoutIfNeeded()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
      layoutIfNeeded()
    }
  }
}

class TrackerDayHabitContentView: UIView, UIContentView {
  private var currentConfiguration: TrackerDayHabitContentConfiguration!
  var configuration: UIContentConfiguration {
    get { currentConfiguration }
    set {
      guard let newConfiguration = newValue as? TrackerDayHabitContentConfiguration else { return }
      apply(configuration: newConfiguration)
    }
  }

  private let titleLabel = UILabel()
  private let completionButton = UIButton()
  private let backgroundView = GradientLayerView()

  init(configuration: TrackerDayHabitContentConfiguration) {
    super.init(frame: .zero)
    setupViews()
    apply(configuration: configuration)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    addPinnedSubview(backgroundView, insets: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8), layoutGuide: safeAreaLayoutGuide, flexibleBottom: true, flexibleTrailing: true)
    backgroundView.layer.cornerRadius = 8
    
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .equalSpacing
    stackView.alignment = .center
    stackView.spacing = 8
    addPinnedSubview(stackView, insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16), layoutGuide: safeAreaLayoutGuide, flexibleBottom: true, flexibleTrailing: true)

    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0
    stackView.addArrangedSubview(titleLabel)

    stackView.addArrangedSubview(completionButton)
    completionButton.addTarget(self, action: #selector(completionHandler), for: .touchUpInside)
    completionButton.heightAnchor.constraint(equalTo: completionButton.widthAnchor).isActive = true
    completionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
    
    var buttonConfiguration = UIButton.Configuration.bordered()
    buttonConfiguration.background.strokeColor = .contrastColor
    buttonConfiguration.background.strokeWidth = 2
    buttonConfiguration.cornerStyle = .capsule
    buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    buttonConfiguration.image = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(scale: .medium))
    completionButton.configuration = buttonConfiguration
    
    completionButton.configurationUpdateHandler = { [weak self] button in
      guard let self else { return }
      var buttonConfiguration = button.configuration
      buttonConfiguration?.baseBackgroundColor = currentConfiguration.isCompleted ? currentConfiguration.color : .backgroundColor
      buttonConfiguration?.imageColorTransformer = UIConfigurationColorTransformer { [weak self] _ in
        guard let self, self.currentConfiguration.isCompleted else { return .clear }
        return .contrastColor
      }
      buttonConfiguration?.baseForegroundColor = currentConfiguration.isCompleted ? .contrastColor : .clear
      UIView.performWithoutAnimation {
        button.configuration = buttonConfiguration
      }
    }
    
    isAccessibilityElement = true
    accessibilityTraits = .button
    accessibilityHint = "Double tap to toggle completion"
  }

  func apply(configuration: TrackerDayHabitContentConfiguration) {
    guard configuration != currentConfiguration else { return }
    currentConfiguration = configuration

    titleLabel.text = configuration.title
    backgroundView.updateColors(startColor: configuration.color, endColor: UIColor.systemGray6)

    completionButton.setNeedsUpdateConfiguration()
    
    accessibilityLabel = "\(configuration.title), \(configuration.isCompleted ? "" : "not ") completed"
  }
  
  @objc private func completionHandler() {
    currentConfiguration.completion?()
  }
  
  override func accessibilityActivate() -> Bool {
    currentConfiguration.completion?()
    return true
  }
}

struct TrackerDayHabitContentConfiguration: UIContentConfiguration, Hashable {
  var title: String = ""
  var color: UIColor = .clear
  var isCompleted: Bool = false
  var completion: (() -> Void)? = nil

  func makeContentView() -> UIView & UIContentView {
    return TrackerDayHabitContentView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> TrackerDayHabitContentConfiguration {
    return self
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(title)
    hasher.combine(isCompleted)
    hasher.combine(color)
  }
  
  static func ==(lhs: TrackerDayHabitContentConfiguration, rhs: TrackerDayHabitContentConfiguration) -> Bool {
    return lhs.isCompleted == rhs.isCompleted && lhs.title == rhs.title && lhs.color == rhs.color
  }
}

class TrackerDayHabitListCell: UICollectionViewListCell {
  func createConfiguration(habit: Habit, isCompleted: Bool, completion: @escaping () -> Void) {
    var newConfiguration = TrackerDayHabitContentConfiguration()
    newConfiguration.title = habit.title ?? ""
    newConfiguration.color = habit.category?.color ?? .systemGray6
    newConfiguration.isCompleted = isCompleted
    newConfiguration.completion = completion
    contentConfiguration = newConfiguration
  }
}
