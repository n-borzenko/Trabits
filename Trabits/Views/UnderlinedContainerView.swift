//
//  UnderlinedContainerView.swift
//  Trabits
//
//  Created by Natalia Borzenko on 09/11/2023.
//

import UIKit

class UnderlinedContainerView: UIView {
  var isLineVisible = false {
    didSet {
      lineBorderView.backgroundColor = isLineVisible ? .neutral30 : .clear
    }
  }
  
  private let lineBorderView = UIView()
  private let stackView = UIStackView()
  
  init() {
    super.init(frame: .zero)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func appendSubview(_ view: UIView) {
    stackView.addArrangedSubview(view)
  }
}

extension UnderlinedContainerView {
  private func setupViews() {
    stackView.axis = .vertical
    stackView.alignment = .fill
    stackView.distribution = .fill
    stackView.spacing = 8
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)
    stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
    stackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive = true
    stackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
    
    lineBorderView.backgroundColor = .clear
    lineBorderView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(lineBorderView)
    lineBorderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    lineBorderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    lineBorderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    lineBorderView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    
    let internalConstraint = lineBorderView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8)
    internalConstraint.priority = .defaultHigh
    internalConstraint.isActive = true
  }
}
