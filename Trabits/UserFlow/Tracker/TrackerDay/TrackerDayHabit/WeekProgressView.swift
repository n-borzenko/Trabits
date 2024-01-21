//
//  WeekProgressView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/01/2024.
//

import UIKit

class WeekProgressCircleView: UIView {
  var color: UIColor {
    didSet {
      updateProgressAndColors()
    }
  }
  
  var progress: HabitWeekResults.DayProgress {
    didSet {
      updateProgressAndColors()
    }
  }
  
  private let colorLayer = CALayer()
  private let dotLayer = CAShapeLayer()
  
  init(color: UIColor = .neutral10, progress: HabitWeekResults.DayProgress = .none) {
    self.color = color
    self.progress = progress
    super.init(frame: .zero)
    setupViews()
    updateProgressAndColors()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupViews() {
    backgroundColor = .systemBackground
    layer.borderColor = UIColor.systemBackground.cgColor
    layer.borderWidth = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
    
    colorLayer.backgroundColor = UIColor.clear.cgColor
    layer.addSublayer(colorLayer)
    dotLayer.fillColor = UIColor.systemBackground.cgColor
    layer.addSublayer(dotLayer)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    updateLayers()
  }
  
  private func updateLayers() {
    layer.borderWidth = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
    layer.cornerRadius = bounds.height / 2
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    colorLayer.frame = bounds
    colorLayer.cornerRadius = bounds.height / 2
    CATransaction.commit()
    
    let dotWidth: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 4 : 2
    let rect = CGRect(x: bounds.midX - dotWidth / 2, y: bounds.midY - dotWidth / 2, width: dotWidth, height: dotWidth)
    dotLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: dotWidth / 2).cgPath
  }
  
  private func updateProgressAndColors() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    switch progress {
    case .none:
      layer.borderColor = UIColor.systemBackground.cgColor
      colorLayer.backgroundColor = UIColor.clear.cgColor
      dotLayer.fillColor = UIColor.systemBackground.cgColor
    case .partial:
      layer.borderColor = UIColor.contrast.cgColor
      colorLayer.backgroundColor = color.withAlphaComponent(0.6).cgColor
      dotLayer.fillColor = UIColor.clear.cgColor
    case .completed:
      layer.borderColor = UIColor.contrast.cgColor
      colorLayer.backgroundColor = color.cgColor
      dotLayer.fillColor = UIColor.contrast.cgColor
    }
    CATransaction.commit()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      updateProgressAndColors()
    }
  }
}

class WeekProgressView: UIView {
  var color: UIColor {
    didSet {
      for subview in stackView.arrangedSubviews {
        guard let circleView = subview as? WeekProgressCircleView else { continue }
        circleView.color = color
      }
    }
  }
  
  var progress: [HabitWeekResults.DayProgress] {
    didSet {
      guard progress.count == stackView.arrangedSubviews.count else { return }
      for i in 0..<progress.count {
        guard let circleView = stackView.arrangedSubviews[i] as? WeekProgressCircleView else { continue }
        circleView.progress = progress[i]
      }
    }
  }
  
  private let stackView = UIStackView()
  private var heightConstraint: NSLayoutConstraint!
  
  init(color: UIColor = .neutral10, progress: [HabitWeekResults.DayProgress] = Array(repeating: .none, count: 7)) {
    self.color = color
    self.progress = progress
    super.init(frame: .zero)
    setupViews()
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    stackView.axis = .horizontal
    stackView.distribution = .equalSpacing
    stackView.spacing = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
    addPinnedSubview(stackView, flexibleBottom: true, flexibleTrailing: true)
    
    let height: Double = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 20 : 10
    heightConstraint = stackView.heightAnchor.constraint(equalToConstant: height)
    heightConstraint.isActive = true
    
    for dayProgress in progress {
      let circleView = WeekProgressCircleView(color: color, progress: dayProgress)
      stackView.addArrangedSubview(circleView)
      circleView.widthAnchor.constraint(equalTo: circleView.heightAnchor).isActive = true
    }
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.preferredContentSizeCategory.isAccessibilityCategory != previousTraitCollection?.preferredContentSizeCategory.isAccessibilityCategory {
      heightConstraint.constant = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 20 : 10
      stackView.spacing = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 2 : 1
    }
  }
}
