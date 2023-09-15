//
//  ColorPickerListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 15/09/2023.
//

import UIKit

protocol ColorPickerListCellDelegate: AnyObject {
  func colorValueChanged(_ color: UIColor?)
}

class ColorPickerListCell: UICollectionViewListCell {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  private var selectedIndex: Int?

  weak var delegate: ColorPickerListCellDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    let verticalInset = 8.0
    let buttonHeight = 44.0
    contentView.addPinnedSubview(scrollView, layoutGuide: contentView.layoutMarginsGuide, flexibleBottom: true)
    scrollView.heightAnchor.constraint(equalToConstant: buttonHeight + 2 * verticalInset).isActive = true

    stackView.axis = .horizontal
    stackView.spacing = 16
    stackView.distribution = .fillEqually
    scrollView.addPinnedSubview(stackView, insets: UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0))

    for (index, item) in ColorPalette.allCases.enumerated() {
      let button = UIButton()
      button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
      button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

      button.accessibilityLabel = "\(item.rawValue)"
      button.accessibilityHint = "Select \(item.rawValue)"

      button.backgroundColor = item.color
      button.tintColor = .contrastColor

      button.layer.cornerRadius = buttonHeight / 2
      button.layer.borderColor = UIColor.contrastColor.cgColor
      button.layer.borderWidth = 1
      if index == selectedIndex {
        button.layer.borderWidth = 3
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        button.accessibilityLabel = "\(item.rawValue) - selected"
      }

      button.tag = index
      button.addTarget(self, action: #selector(selectColorHandler), for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }
  }

  func fill(selectedColor: UIColor?) {
    if let selectedColor = selectedColor,
       let index = ColorPalette.allCases.firstIndex(where: { $0.color == selectedColor }) {
      selectItem(at: index, isScrollingActive: true)
    }
  }

  @objc private func selectColorHandler(_ button: UIButton) {
    let index = button.tag
    deselectItem()
    selectItem(at: index)
    delegate?.colorValueChanged(ColorPalette.allCases[index].color)
  }

  private func selectItem(at index: Int, isScrollingActive: Bool = false) {
    if let button = stackView.arrangedSubviews[index] as? UIButton {
      selectedIndex = index
      button.layer.borderWidth = 3
      button.setImage(UIImage(systemName: "checkmark"), for: .normal)
      button.accessibilityLabel = "\(ColorPalette.allCases[index].rawValue) - selected"

      if isScrollingActive {
        Task {
          await MainActor.run {
            scrollView.scrollRectToVisible(button.frame, animated: false)
          }
        }
      }
    }
  }

  private func deselectItem() {
    if let index = selectedIndex,
       let button = stackView.arrangedSubviews[index] as? UIButton {
      button.layer.borderWidth = 1
      button.setImage(nil, for: .normal)
      button.accessibilityLabel = "\(ColorPalette.allCases[index].rawValue)"
    }
    selectedIndex = nil
  }

  override func prepareForReuse() {
    deselectItem()
    super.prepareForReuse()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      stackView.arrangedSubviews.forEach { view in
        view.layer.borderColor = UIColor.contrastColor.cgColor
      }
    }
  }
}
