//
//  EmptyStateView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/08/2023.
//

import UIKit
import SwiftUI

struct EmptyStateWrapperView: UIViewRepresentable {
  var message: String
  var actionTitle: String
  var action: () -> Void
  
  func makeUIView(context: Context) -> EmptyStateView {
    let emptyStateView = EmptyStateView(message: message, actionTitle: actionTitle, action: action)
    return emptyStateView
  }
  
  func updateUIView(_ uiView: EmptyStateView, context: Context) {
    uiView.message = message
    uiView.actionTitle = actionTitle
    uiView.action = action
  }
}

class EmptyStateView: UIView {
  private var centerYConstraint: NSLayoutConstraint!
  private let titleLabel = UILabel()
  private let actionButton = UIButton()
  
  var message: String {
    didSet {
      titleLabel.text = message
    }
  }
  
  var actionTitle: String {
    didSet {
      var buttonConfiguration = actionButton.configuration
      buttonConfiguration?.title = actionTitle
      actionButton.configuration = buttonConfiguration
    }
  }
  
  var action: () -> Void
  
  init(message: String = "List is empty", actionTitle: String, action: @escaping () -> Void) {
    self.message = message
    self.actionTitle = actionTitle
    self.action = action
    super.init(frame: .zero)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension EmptyStateView {
  private func setupViews() {
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
    
    let imageView = UIImageView(image: UIImage.emptyState)
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
    titleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.adjustsFontSizeToFitWidth = true
    stackView.addArrangedSubview(titleLabel)
    
    var buttonConfiguration = UIButton.Configuration.borderedProminent()
    buttonConfiguration.title = actionTitle
    actionButton.configuration = buttonConfiguration
    actionButton.addTarget(self, action: #selector(actionHandler), for: .touchUpInside)
    stackView.addArrangedSubview(actionButton)
    actionButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
  }
  
  @objc private func actionHandler() {
    action()
  }
  
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
      centerYConstraint.constant = traitCollection.verticalSizeClass == .compact ? 0 : -20
    }
  }
}
