//
//  TrackerDayHabitResultsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 10/01/2024.
//

import UIKit

class TrackerDayHabitResultsView: UIView {
  var configuration: TrackerDayHabitContentConfiguration? {
    didSet { applyConfiguration() }
  }

  private let stackView = UIStackView()
  private var dayProgressViewHeightConstraint: NSLayoutConstraint!

  private let weekResultsStackView = UIStackView()
  private var weekResultLabelImage: UIImageView!
  private let weekResultLabel = UILabel()
  private let weekProgressView = WeekProgressView()

  private let dayResultsStackView = UIStackView()
  private var dayResultLabelImage: UIImageView!
  private let dayResultLabel = UILabel()
  private let dayProgressView = UIProgressView()

  init(configuration: TrackerDayHabitContentConfiguration? = nil) {
    self.configuration = configuration
    super.init(frame: .zero)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func applyConfiguration() {
    guard let configuration else { return }
    let weekResults = configuration.weekResults
    if weekResults.weekGoal > 0 {
      weekResultLabel.text = "\(weekResults.weekResult)/\(weekResults.weekGoal)"
      weekResultLabel.textColor = .secondaryLabel
      weekResultLabelImage.isHidden = false
    } else if weekResults.weekResult > 0 {
      weekResultLabel.text = "\(weekResults.weekResult)"
      weekResultLabel.textColor = .secondaryLabel
      weekResultLabelImage.isHidden = true
    } else {
      weekResultLabel.text = "0"
      weekResultLabel.textColor = .clear
      weekResultLabelImage.isHidden = true
    }

    weekProgressView.color = configuration.color
    weekProgressView.progress = weekResults.progress

    if weekResults.completionTarget > 1 {
      dayResultLabel.text = "\(weekResults.completionCount)/\(weekResults.completionTarget)"
      dayResultLabel.textColor = .secondaryLabel
      dayResultLabelImage.isHidden = false
    } else if weekResults.completionCount > 1 {
      dayResultLabel.text = "\(weekResults.completionCount)"
      dayResultLabel.textColor = .secondaryLabel
      dayResultLabelImage.isHidden = true
    } else {
      dayResultLabel.text = "0"
      dayResultLabel.textColor = .clear
      dayResultLabelImage.isHidden = true
    }

    dayProgressView.setProgress(
      min(Float(weekResults.completionCount) / Float(weekResults.completionTarget), 1),
      animated: false
    )
    dayProgressView.progressTintColor = configuration.color

    accessibilityLabel = weekResults.accessibilityLongDescription
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    let isDifferentAccessibilityCategory = isAccessibilityCategory !=
      previousTraitCollection?.preferredContentSizeCategory.isAccessibilityCategory
    let isDifferentHorizontalSizeClass = traitCollection.horizontalSizeClass !=
      previousTraitCollection?.horizontalSizeClass

    if isDifferentAccessibilityCategory {
      let dayProgressViewHeight: Double = isAccessibilityCategory ? 20 : 10
      dayProgressViewHeightConstraint.constant = dayProgressViewHeight
      dayProgressView.layer.sublayers?.last?.borderWidth = isAccessibilityCategory ? 2 : 1
      dayProgressView.subviews.forEach { $0.layer.cornerRadius = dayProgressViewHeight / 2 }
    }

    if isDifferentAccessibilityCategory || isDifferentHorizontalSizeClass {
      let isCompact = isAccessibilityCategory && traitCollection.horizontalSizeClass == .compact
      stackView.alignment = isCompact ? .bottom : .center

      weekResultsStackView.axis = isCompact ? .vertical : .horizontal
      weekResultsStackView.alignment = isCompact ? .leading : .center
      if isCompact && weekResultsStackView.arrangedSubviews[0] == weekProgressView ||
          !isCompact && weekResultsStackView.arrangedSubviews[0] != weekProgressView {
        weekResultsStackView.addArrangedSubview(weekResultsStackView.arrangedSubviews[0])
      }

      dayResultsStackView.axis = isCompact ? .vertical : .horizontal
      dayResultsStackView.alignment = isCompact ? .trailing : .center

      // TrackerDayHabitListCell height needs to be calculated correctly
      // after rotation from horizontal regular size class
      // to vertical compact size class with preferred accessibility category
      setNeedsLayout()
      layoutIfNeeded()
    }

    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      dayProgressView.layer.sublayers?.last?.borderColor = UIColor.contrast.cgColor
    }
  }
}

extension TrackerDayHabitResultsView {
  private func setupViews() {
    let isCompact = traitCollection.preferredContentSizeCategory.isAccessibilityCategory &&
      traitCollection.horizontalSizeClass == .compact

    stackView.axis = .horizontal
    stackView.alignment = isCompact ? .bottom : .center
    stackView.distribution = .fill
    stackView.spacing = 2
    addPinnedSubview(stackView)

    weekResultsStackView.axis = isCompact ? .vertical : .horizontal
    weekResultsStackView.distribution = .fill
    weekResultsStackView.alignment = isCompact ? .leading : .center
    weekResultsStackView.spacing = 8
    stackView.addArrangedSubview(weekResultsStackView)

    weekResultsStackView.addArrangedSubview(weekProgressView)

    let weekResultLabelStackView = UIStackView()
    weekResultLabelStackView.axis = .horizontal
    weekResultLabelStackView.spacing = 2
    weekResultsStackView.addArrangedSubview(weekResultLabelStackView)

    weekResultLabelImage = UIImageView(image: UIImage(systemName: "flame"))
    weekResultLabelImage.adjustsImageSizeForAccessibilityContentSizeCategory = true
    weekResultLabelImage.preferredSymbolConfiguration = .init(font: .preferredFont(forTextStyle: .caption2))
    weekResultLabelImage.tintColor = .secondaryLabel
    weekResultLabelStackView.addArrangedSubview(weekResultLabelImage)

    weekResultLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    weekResultLabel.adjustsFontForContentSizeCategory = true
    weekResultLabel.numberOfLines = 1
    weekResultLabel.textColor = .secondaryLabel
    weekResultLabelStackView.addArrangedSubview(weekResultLabel)

    if isCompact {
      // reorder weekResultsStackView subviews
      weekResultsStackView.addArrangedSubview(weekProgressView)
    }

    let emptyView = UIView()
    stackView.addArrangedSubview(emptyView)
    emptyView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    emptyView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor).isActive = true
    emptyView.heightAnchor.constraint(equalToConstant: 0).isActive = true

    setupDayResultsStackView(containerStack: stackView, isCompact: isCompact)

    isAccessibilityElement = true
    accessibilityTraits = [.staticText]
  }

  private func setupDayResultsStackView(containerStack: UIStackView, isCompact: Bool) {
    dayResultsStackView.axis = isCompact ? .vertical : .horizontal
    dayResultsStackView.distribution = .fill
    dayResultsStackView.alignment = isCompact ? .trailing : .center
    dayResultsStackView.spacing = 8
    containerStack.addArrangedSubview(dayResultsStackView)

    let dayResultLabelStackView = UIStackView()
    dayResultLabelStackView.axis = .horizontal
    dayResultLabelStackView.spacing = 2
    dayResultsStackView.addArrangedSubview(dayResultLabelStackView)

    dayResultLabelImage = UIImageView(image: UIImage(systemName: "target"))
    dayResultLabelImage.adjustsImageSizeForAccessibilityContentSizeCategory = true
    dayResultLabelImage.preferredSymbolConfiguration = .init(font: .preferredFont(forTextStyle: .caption2))
    dayResultLabelImage.tintColor = .secondaryLabel
    dayResultLabelStackView.addArrangedSubview(dayResultLabelImage)

    dayResultLabel.font = UIFont.preferredFont(forTextStyle: .caption2)
    dayResultLabel.adjustsFontForContentSizeCategory = true
    dayResultLabel.numberOfLines = 1
    dayResultLabel.textColor = .secondaryLabel
    dayResultLabel.textAlignment = .right
    dayResultLabelStackView.addArrangedSubview(dayResultLabel)

    let isAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
    let dayProgressViewHeight: Double = isAccessibilityCategory ? 20 : 10
    dayProgressView.trackTintColor = .systemBackground
    dayProgressView.layer.sublayers?.last?.borderColor = UIColor.contrast.cgColor
    dayProgressView.layer.sublayers?.last?.borderWidth = isAccessibilityCategory ? 2 : 1
    dayProgressView.subviews.forEach {
      $0.layer.cornerRadius = dayProgressViewHeight / 2
      $0.clipsToBounds = true
    }

    dayResultsStackView.addArrangedSubview(dayProgressView)
    dayProgressViewHeightConstraint = dayProgressView.heightAnchor.constraint(equalToConstant: dayProgressViewHeight)
    dayProgressViewHeightConstraint.isActive = true
    dayProgressView.widthAnchor.constraint(
      greaterThanOrEqualTo: weekProgressView.widthAnchor
    ).isActive = true
    dayProgressView.widthAnchor.constraint(
      lessThanOrEqualTo: weekProgressView.widthAnchor,
      multiplier: 1.5
    ).isActive = true
  }
}
