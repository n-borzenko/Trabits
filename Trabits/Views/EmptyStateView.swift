//
//  EmptyStateView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/08/2023.
//

import UIKit

class EmptyStateView: UIView {
  private var centerYConstraint: NSLayoutConstraint!
  private let titleLabel = UILabel()
  
  var message: String {
    didSet {
      titleLabel.text = message
    }
  }
  
  init(message: String = "List is empty", image: UIImage? = nil) {
    self.message = message
    super.init(frame: .zero)
    setupViews(image: image)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override class var requiresConstraintBasedLayout: Bool {
    true
  }
}

extension EmptyStateView {
  private func setupViews(image: UIImage?) {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.spacing = 16
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    centerYConstraint = stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
    centerYConstraint.constant = traitCollection.verticalSizeClass == .compact ? 0 : -20
    centerYConstraint.isActive = true
    stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
    stackView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.8).isActive = true
    
    let imageView = UIImageView(image: image ?? UIImage.emptyState)
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .tertiaryLabel
    imageView.isAccessibilityElement = false
    stackView.addArrangedSubview(imageView)
    
    imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
    let imageWidthConstraint = imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.4)
    imageWidthConstraint.priority = .defaultHigh
    imageWidthConstraint.isActive = true
    let imageHeightConstraint = imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.4)
    imageHeightConstraint.priority = .defaultHigh
    imageHeightConstraint.isActive = true
    
    titleLabel.text = message
    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.adjustsFontSizeToFitWidth = true
    stackView.addArrangedSubview(titleLabel)
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
      centerYConstraint.constant = traitCollection.verticalSizeClass == .compact ? 0 : -20
    }
  }
}
