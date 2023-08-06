//
//  EmptyStateView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/08/2023.
//

import UIKit

class EmptyStateView: UIView {
  private let titleLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }

  override class var requiresConstraintBasedLayout: Bool {
    true
  }
}

extension EmptyStateView {
  private func setupViews() {
    titleLabel.text = "List is empty"
    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleLabel)

    titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0).isActive = true
    titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0).isActive = true

    let widthConstraint = titleLabel.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.8)
    widthConstraint.priority = .defaultHigh
    widthConstraint.isActive = true
  }
}
