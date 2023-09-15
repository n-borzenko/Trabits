//
//  UIView+PinnedSubview.swift
//  Trabits
//
//  Created by Natalia Borzenko on 23/08/2023.
//

import UIKit

extension UIView {
  func addPinnedSubview(
    _ subview: UIView,
    insets: UIEdgeInsets = UIEdgeInsets.zero,
    layoutGuide: UILayoutGuide? = nil,
    flexibleBottom: Bool = false
  ) {
    addSubview(subview)
    subview.translatesAutoresizingMaskIntoConstraints = false
    subview.topAnchor.constraint(equalTo: layoutGuide?.topAnchor ?? topAnchor, constant: insets.top).isActive = true
    subview.leadingAnchor.constraint(equalTo: layoutGuide?.leadingAnchor ?? leadingAnchor, constant: insets.left).isActive = true
    subview.trailingAnchor.constraint(equalTo: layoutGuide?.trailingAnchor ?? trailingAnchor, constant: -insets.right).isActive = true
    let bottomConstraint = subview.bottomAnchor.constraint(equalTo: layoutGuide?.bottomAnchor ?? bottomAnchor, constant: -insets.bottom)
    if flexibleBottom {
      bottomConstraint.priority = .defaultHigh
    }
    bottomConstraint.isActive = true
  }
}
