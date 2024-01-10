//
//  TrackerDayHabitResultsView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 10/01/2024.
//

import UIKit

class TrackerDayHabitResultsView: UIView {
  var configuration: TrackerDayHabitContentConfiguration? = nil {
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
    if configuration.weekGoal > 0 {
      weekResultLabel.text = "\(configuration.weekResult)/\(configuration.weekGoal)"
      weekResultLabel.isHidden = false
      weekResultLabelImage.isHidden = false
    } else if configuration.weekResult > 0 {
      weekResultLabel.text = "\(configuration.weekResult)"
      weekResultLabel.isHidden = false
      weekResultLabelImage.isHidden = true
    } else {
      weekResultLabel.text = nil
      weekResultLabel.isHidden = true
      weekResultLabelImage.isHidden = true
    }
    
    weekProgressView.color = configuration.color
    weekProgressView.progress = configuration.progress
    
    if configuration.completionTarget > 1 {
      dayResultLabel.text = "\(configuration.completionCount)/\(configuration.completionTarget)"
      dayResultLabel.isHidden = false
      dayResultLabelImage.isHidden = false
    } else if configuration.completionCount > 1 {
      dayResultLabel.text = "\(configuration.completionCount)"
      dayResultLabel.isHidden = false
      dayResultLabelImage.isHidden = true
    } else {
      dayResultLabel.text = nil
      dayResultLabel.isHidden = true
      dayResultLabelImage.isHidden = true
    }
    
    dayProgressView.progress = min(Float(configuration.completionCount) / Float(configuration.completionTarget), 1)
    dayProgressView.progressTintColor = configuration.color
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    let isDifferentAccessibilityCategory = traitCollection.preferredContentSizeCategory.isAccessibilityCategory != previousTraitCollection?.preferredContentSizeCategory.isAccessibilityCategory
    let isDifferentHorizontalSizeClass = traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass
    
    if isDifferentAccessibilityCategory {
      let dayProgressViewHeight: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 20 : 10
      dayProgressViewHeightConstraint.constant = dayProgressViewHeight
      dayProgressView.layer.sublayers?.last?.borderWidth = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
      dayProgressView.subviews.forEach { $0.layer.cornerRadius = dayProgressViewHeight / 2 }
    }
        
    if isDifferentAccessibilityCategory || isDifferentHorizontalSizeClass {
      let isCompact = traitCollection.preferredContentSizeCategory.isAccessibilityCategory && traitCollection.horizontalSizeClass == .compact
      stackView.alignment = isCompact ? .bottom : .center
      
      weekResultsStackView.axis = isCompact ? .vertical : .horizontal
      weekResultsStackView.alignment = isCompact ? .leading : .center
      if isCompact && weekResultsStackView.arrangedSubviews[0] == weekProgressView ||
          !isCompact && weekResultsStackView.arrangedSubviews[0] != weekProgressView {
        weekResultsStackView.addArrangedSubview(weekResultsStackView.arrangedSubviews[0])
      }
      
      dayResultsStackView.axis = isCompact ? .vertical : .horizontal
      dayResultsStackView.alignment = isCompact ? .trailing : .center
      
      // TrackerDayHabitListCell height needs to be calculated correctly after rotation from horizontal regular size class
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
    let isCompact = traitCollection.preferredContentSizeCategory.isAccessibilityCategory && traitCollection.horizontalSizeClass == .compact
    
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
    
    dayResultsStackView.axis = isCompact ? .vertical : .horizontal
    dayResultsStackView.distribution = .fill
    dayResultsStackView.alignment = isCompact ? .trailing : .center
    dayResultsStackView.spacing = 8
    stackView.addArrangedSubview(dayResultsStackView)
    
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
    
    let dayProgressViewHeight: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 20 : 10
    dayProgressView.trackTintColor = .systemBackground
    dayProgressView.layer.sublayers?.last?.borderColor = UIColor.contrast.cgColor
    dayProgressView.layer.sublayers?.last?.borderWidth = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
    dayProgressView.subviews.forEach {
      $0.layer.cornerRadius = dayProgressViewHeight / 2
      $0.clipsToBounds = true
    }
    
    dayResultsStackView.addArrangedSubview(dayProgressView)
    dayProgressViewHeightConstraint = dayProgressView.heightAnchor.constraint(equalToConstant: dayProgressViewHeight)
    dayProgressViewHeightConstraint.isActive = true
    dayProgressView.widthAnchor.constraint(greaterThanOrEqualTo: weekProgressView.widthAnchor).isActive = true
    dayProgressView.widthAnchor.constraint(lessThanOrEqualTo: weekProgressView.widthAnchor, multiplier: 1.5).isActive = true
  }
}
