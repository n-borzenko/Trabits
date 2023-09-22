//
//  EmptyStateView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/08/2023.
//

import UIKit

class EmptyStateView: UIView {
  init(message: String = "List is empty", image: UIImage? = nil) {
    super.init(frame: .zero)
    setupViews(message: message, image: image)
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
  private func setupViews(message: String, image: UIImage?) {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.spacing = 20

    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30).isActive = true
    stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    stackView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.8).isActive = true
    stackView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor).isActive = true

    if let image {
      let imageView = UIImageView(image: image)
      imageView.contentMode = .scaleAspectFit
      imageView.tintColor = .tertiaryLabel
      stackView.addArrangedSubview(imageView)

      imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
      let imageWidthConstraint = imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.4)
      imageWidthConstraint.priority = .defaultHigh
      imageWidthConstraint.isActive = true
      let imageHeightConstraint = imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.4)
      imageHeightConstraint.priority = .defaultHigh
      imageHeightConstraint.isActive = true
    }

    let titleLabel = UILabel()
    titleLabel.text = message
    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    stackView.addArrangedSubview(titleLabel)
  }
}
