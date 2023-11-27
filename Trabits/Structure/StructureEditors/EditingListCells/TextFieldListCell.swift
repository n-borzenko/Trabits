//
//  TextFieldListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/08/2023.
//

import UIKit

protocol TextFieldListCellDelegate: AnyObject {
  func textValueChanged(_ text: String?)
}

class TextFieldListCell: UICollectionViewListCell {
  let textField = UITextField()
  weak var delegate: TextFieldListCellDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    contentView.addPinnedSubview(textField, layoutGuide: contentView.layoutMarginsGuide)
    textField.addTarget(self, action: #selector(textValueChanged), for: .editingChanged)
    textField.clearButtonMode = .whileEditing
    textField.font = UIFont.preferredFont(forTextStyle: .body)
    textField.adjustsFontForContentSizeCategory = true
    textField.delegate = self
  }

  @objc private func textValueChanged(_ sender: UITextField) {
    delegate?.textValueChanged(sender.text)
  }
}

extension TextFieldListCell: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}
