//
//  CategoryPickerListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 25/08/2023.
//

import UIKit

class CategoryPickerRowView: UIView {
  private var label = UILabel()
  private var backgroundView = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func fill(with category: Category, isSelected: Bool) {
    label.text = category.title
    backgroundView.backgroundColor = category.color ?? .clear
    backgroundView.layer.borderColor = isSelected ? UIColor.contrastColor.cgColor : UIColor.clear.cgColor
  }

  private func setupViews() {
    addPinnedSubview(backgroundView, insets: UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4))
    addPinnedSubview(label, insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

    backgroundView.layer.borderWidth = 1
    backgroundView.layer.cornerRadius = 8
    backgroundView.layer.cornerCurve = .continuous
  }
}

protocol CategoryPickerListCellDelegate: AnyObject {
  func selectedCategoryIndexChanged(_ index: Int?)
}

class CategoryPickerListCell: UICollectionViewListCell {
  private let pickerView = UIPickerView()
  private var categories: [Category] = []
  private var selectedIndex: Int?

  weak var delegate: CategoryPickerListCellDelegate?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    contentView.addPinnedSubview(pickerView, layoutGuide: contentView.layoutMarginsGuide, flexibleBottom: true)
    pickerView.delegate = self
    pickerView.dataSource = self
  }

  override func prepareForReuse() {
    categories = []
    selectedIndex = nil
    super.prepareForReuse()
  }

  func fill(with categories: [Category], selectedIndex: Int?) {
    self.categories = categories
    self.selectedIndex = selectedIndex
    pickerView.reloadAllComponents()
    if let selectedIndex = selectedIndex {
      pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
    }
  }
}

extension CategoryPickerListCell: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    component == 0 ? categories.count : 0
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    component == 0 ? 44 : 0
  }

  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    var categoryRow: CategoryPickerRowView
    if let row = view as? CategoryPickerRowView {
      categoryRow = row
    } else {
      categoryRow = CategoryPickerRowView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    }
    categoryRow.fill(with: categories[row], isSelected: selectedIndex == row)
    return categoryRow
  }
}

extension CategoryPickerListCell: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    guard component == 0 && row < categories.count else { return }
    delegate?.selectedCategoryIndexChanged(row)
    selectedIndex = row
    pickerView.reloadAllComponents()
  }
}
