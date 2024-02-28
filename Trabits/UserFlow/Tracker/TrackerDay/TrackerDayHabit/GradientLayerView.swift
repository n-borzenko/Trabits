//
//  GradientLayerView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/01/2024.
//

import UIKit

final class GradientLayerView: UIView {
  override class var layerClass: AnyClass {
    return CAGradientLayer.self
  }

  private var gradientLayer: CAGradientLayer {
    return self.layer as! CAGradientLayer
  }

  var completion: (() -> Void)?

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

  override var accessibilityFrame: CGRect {
    get { UIAccessibility.convertToScreenCoordinates(bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)), in: self) }
    set { super.accessibilityFrame = newValue }
  }

  override func accessibilityActivate() -> Bool {
    completion?()
    return true
  }
}
