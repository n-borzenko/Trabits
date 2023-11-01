//
//  ActionButton.swift
//  Trabits
//
//  Created by Natalia Borzenko on 01/09/2023.
//

import UIKit

class ActionButton: UIButton {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = bounds.height / 2
  }

  private func setupViews() {
    backgroundColor = .systemGray5
    setTitleColor(.contrast, for: .normal)
    setTitleColor(.contrast.withAlphaComponent(0.6), for: .highlighted)
    layer.shadowOpacity = 0.2
    layer.shadowRadius = 6
    layer.shadowOffset = CGSize(width: 2, height: 4)
    layer.cornerCurve = .continuous
    titleLabel?.adjustsFontSizeToFitWidth = true
    titleLabel?.adjustsFontForContentSizeCategory = true
    titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    titleEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
  }
}
