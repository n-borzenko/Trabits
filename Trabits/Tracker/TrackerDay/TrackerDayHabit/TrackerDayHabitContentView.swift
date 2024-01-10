//
//  TrackerDayHabitContentView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/01/2024.
//

import UIKit

class TrackerDayHabitContentView: UIView, UIContentView {
  private var currentConfiguration: TrackerDayHabitContentConfiguration!
  var configuration: UIContentConfiguration {
    get { currentConfiguration }
    set {
      guard let newConfiguration = newValue as? TrackerDayHabitContentConfiguration else { return }
      apply(configuration: newConfiguration)
    }
  }

  private let stackView = UIStackView()
  private let titleLabel = UILabel()
  private let archivedLabel = LabelWithInsets()
  private let categoryLabel = LabelWithInsets()
  private let completionButton = UIButton()
  private let resultsView = TrackerDayHabitResultsView()
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

  func apply(configuration: TrackerDayHabitContentConfiguration) {
    guard configuration != currentConfiguration else { return }
    currentConfiguration = configuration

    archivedLabel.isHidden = !configuration.isArchived
    titleLabel.text = configuration.title
    if let categoryTitle = configuration.categoryTitle {
      categoryLabel.text = categoryTitle
      categoryLabel.isHidden = false
    } else {
      categoryLabel.text = nil
      categoryLabel.isHidden = true
    }
    backgroundView.updateColors(startColor: configuration.color, endColor: .neutral5)

    var buttonConfiguration = completionButton.configuration
    let isCompleted = configuration.completionCount >= configuration.completionTarget
    buttonConfiguration?.baseBackgroundColor = configuration.completionCount > 0 ?
      configuration.color.withAlphaComponent(isCompleted ? 1 : 0.3) : .systemBackground
    let imageConfiguration = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .title2), scale: .medium)
    buttonConfiguration?.image = UIImage(systemName: isCompleted ? "checkmark" : "plus", withConfiguration: imageConfiguration)
    completionButton.configuration = buttonConfiguration
    
    resultsView.configuration = configuration
    
//    accessibilityLabel = "\(configuration.title), \(configuration.isCompleted ? "" : "not ") completed"
  }
  
  @objc private func completionHandler() {
    currentConfiguration.completion?()
  }
  
  override func accessibilityActivate() -> Bool {
    currentConfiguration.completion?()
    return true
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.preferredContentSizeCategory.isAccessibilityCategory != previousTraitCollection?.preferredContentSizeCategory.isAccessibilityCategory {
      stackView.spacing = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 8 : 4
      categoryLabel.numberOfLines = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1

      var buttonConfiguration = completionButton.configuration
      let insetSize: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 13 : 8
      buttonConfiguration?.contentInsets = NSDirectionalEdgeInsets(top: insetSize, leading: insetSize, bottom: insetSize, trailing: insetSize)
      let strokeWidth: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 3 : 2
      buttonConfiguration?.background.strokeWidth = strokeWidth
      completionButton.configuration = buttonConfiguration
    }
  }
}

extension TrackerDayHabitContentView {
  private func setupViews() {
    addPinnedSubview(backgroundView, insets: UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12), layoutGuide: safeAreaLayoutGuide, flexibleBottom: true, flexibleTrailing: true)
    backgroundView.layer.cornerRadius = 8
    
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 8 : 4
    addPinnedSubview(stackView, insets: UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20), layoutGuide: safeAreaLayoutGuide, flexibleBottom: true, flexibleTrailing: true)
    
    let mainStackView = UIStackView()
    mainStackView.axis = .horizontal
    mainStackView.distribution = .equalSpacing
    mainStackView.alignment = .center
    mainStackView.spacing = 16
    stackView.addArrangedSubview(mainStackView)
    
    let titleAndLabelsStackView = UIStackView()
    titleAndLabelsStackView.axis = .vertical
    titleAndLabelsStackView.distribution = .equalSpacing
    titleAndLabelsStackView.alignment = .leading
    titleAndLabelsStackView.spacing = 4
    mainStackView.addArrangedSubview(titleAndLabelsStackView)
    
    archivedLabel.text = "Archived"
    archivedLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    archivedLabel.adjustsFontForContentSizeCategory = true
    archivedLabel.leftInset = 4
    archivedLabel.rightInset = 4
    archivedLabel.textColor = .inverted
    archivedLabel.backgroundColor = .neutral80.withAlphaComponent(0.8)
    archivedLabel.layer.masksToBounds = true
    archivedLabel.layer.cornerRadius = 4
    titleAndLabelsStackView.addArrangedSubview(archivedLabel)

    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0
    titleAndLabelsStackView.addArrangedSubview(titleLabel)
    
    categoryLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    categoryLabel.adjustsFontForContentSizeCategory = true
    categoryLabel.numberOfLines = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
    categoryLabel.leftInset = 4
    categoryLabel.rightInset = 4
    categoryLabel.backgroundColor = .systemBackground.withAlphaComponent(0.6)
    categoryLabel.layer.masksToBounds = true
    categoryLabel.layer.cornerRadius = 4
    titleAndLabelsStackView.addArrangedSubview(categoryLabel)

    mainStackView.addArrangedSubview(completionButton)
    completionButton.addTarget(self, action: #selector(completionHandler), for: .touchUpInside)
    completionButton.heightAnchor.constraint(equalTo: completionButton.widthAnchor).isActive = true
    completionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    
    var buttonConfiguration = UIButton.Configuration.bordered()
    buttonConfiguration.background.strokeColor = .contrast
    let strokeWidth: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 3 : 2
    buttonConfiguration.background.strokeWidth = strokeWidth
    buttonConfiguration.cornerStyle = .capsule
    let insetSize: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 13 : 8
    buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: insetSize, leading: insetSize, bottom: insetSize, trailing: insetSize)
    buttonConfiguration.baseForegroundColor = .contrast
    completionButton.configuration = buttonConfiguration
    
    stackView.addArrangedSubview(resultsView)
    resultsView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
    
    isAccessibilityElement = true
    accessibilityTraits = .button
    accessibilityHint = "Double tap to adjust completion"
  }
}
