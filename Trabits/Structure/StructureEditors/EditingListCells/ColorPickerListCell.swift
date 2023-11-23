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

protocol ColorPickerAccessibilityContainerDelegate: AnyObject {
  var totalItemsCount: Int { get }
  var selectedIndex: Int? { get }
  var selectedValue: String? { get }
  func adjustSelection(to index: Int) -> Void
}

class ColorPickerAccessibilityContainerView: UIView {
  weak var delegate: ColorPickerAccessibilityContainerDelegate?
  
  init() {
    super.init(frame: .zero)
    isAccessibilityElement = true
    accessibilityTraits = .adjustable
    accessibilityLabel = "Color selector"
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var accessibilityValue: String? {
    get { delegate?.selectedValue }
    set { super.accessibilityValue = newValue }
  }
  
  override var accessibilityFrame: CGRect {
    get {
      UIAccessibility.convertToScreenCoordinates(
        bounds.inset(by: UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)),
        in: self
      )
    }
    set { super.accessibilityFrame = newValue }
  }
  
  override func accessibilityIncrement() {
    guard let delegate, let selectedIndex = delegate.selectedIndex,
              selectedIndex < (delegate.totalItemsCount - 1) else { return }
    delegate.adjustSelection(to: selectedIndex + 1)
  }
  
  override func accessibilityDecrement() {
    guard let delegate, let selectedIndex = delegate.selectedIndex, selectedIndex > 0 else { return }
    delegate.adjustSelection(to: selectedIndex - 1)
  }
}

class ColorPickerListCell: UICollectionViewListCell, ColorPickerAccessibilityContainerDelegate {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()
  internal var selectedIndex: Int?

  private var accessibilityContainerView: ColorPickerAccessibilityContainerView!
  
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
    accessibilityContainerView = ColorPickerAccessibilityContainerView()
    accessibilityContainerView.delegate = self
    contentView.addPinnedSubview(accessibilityContainerView)
    
    let verticalInset = 8.0
    let buttonHeight = 44.0
    contentView.addPinnedSubview(scrollView, layoutGuide: contentView.layoutMarginsGuide, flexibleBottom: true)
    scrollView.heightAnchor.constraint(equalToConstant: buttonHeight + 2 * verticalInset).isActive = true
    scrollView.showsHorizontalScrollIndicator = false

    stackView.axis = .horizontal
    stackView.spacing = 16
    stackView.distribution = .fillEqually
    scrollView.addPinnedSubview(stackView, insets: UIEdgeInsets(top: verticalInset, left: 0, bottom: verticalInset, right: 0))

    for (index, item) in PastelPalette.colors.enumerated() {
      let button = UIButton()
      button.heightAnchor.constraint(equalTo: button.widthAnchor).isActive = true
      button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

      button.backgroundColor = item
      button.tintColor = .contrast

      button.layer.cornerRadius = buttonHeight / 2
      button.layer.borderColor = UIColor.contrast.cgColor
      button.layer.borderWidth = 1
      if index == selectedIndex {
        button.layer.borderWidth = 3
        button.setImage(UIImage(systemName: "checkmark"), for: .normal)
      }

      button.tag = index
      button.isAccessibilityElement = false
      button.addTarget(self, action: #selector(selectColorHandler), for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }
  }

  func fill(selectedColor: UIColor?) {
    if let selectedColor = selectedColor,
       let index = PastelPalette.colors.firstIndex(where: { $0 == selectedColor }) {
      selectItem(at: index, isScrollingActive: true)
    }
  }

  @objc private func selectColorHandler(_ button: UIButton) {
    let index = button.tag
    deselectItem()
    selectItem(at: index)
    delegate?.colorValueChanged(PastelPalette.colors[index])
  }

  private func selectItem(at index: Int, isScrollingActive: Bool = false) {
    if let button = stackView.arrangedSubviews[index] as? UIButton {
      selectedIndex = index
      button.layer.borderWidth = 3
      button.setImage(UIImage(systemName: "checkmark"), for: .normal)

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
        view.layer.borderColor = UIColor.contrast.cgColor
      }
    }
  }
}

extension ColorPickerListCell {
  var totalItemsCount: Int {
    get { PastelPalette.colors.count }
  }
  
  var selectedValue: String? {
    get {
      guard let selectedIndex else { return nil }
      return PastelPalette.colorTitles[selectedIndex]
    }
  }
  
  func adjustSelection(to index: Int) {
    deselectItem()
    selectItem(at: index, isScrollingActive: true)
    delegate?.colorValueChanged(PastelPalette.colors[index])
  }
}
