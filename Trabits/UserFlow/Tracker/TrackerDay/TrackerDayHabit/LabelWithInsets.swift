//
//  LabelWithInsets.swift
//  Trabits
//
//  Created by Natalia Borzenko on 06/01/2024.
//

import UIKit

class LabelWithInsets: UILabel {
  var topInset: CGFloat = 0
  var bottomInset: CGFloat = 0
  var leftInset: CGFloat = 0
  var rightInset: CGFloat = 0

  override func drawText(in rect: CGRect) {
    let insets = UIEdgeInsets.init(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
    super.drawText(in: rect.inset(by: insets))
  }

  override var intrinsicContentSize: CGSize {
    let size = super.intrinsicContentSize
    return CGSize(
      width: size.width + leftInset + rightInset,
      height: size.height + topInset + bottomInset
    )
  }
}
