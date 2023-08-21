//
//  CategoryCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 20/06/2023.
//

import UIKit

class CategoryCell: UITableViewCell {
  static let reuseIdentifier = String(describing: CategoryCell.self)

  private var titleLabel = UILabel()
  private var habitsCountLabel = UILabel()
  private let rectangleView = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func fill(with category: Category) {
    titleLabel.text = "\(category.orderPriority): \(category.title ?? "")"
    habitsCountLabel.text = "\(category.habits?.count ?? 0)"
    rectangleView.backgroundColor = category.color
  }
}

extension CategoryCell {
  private func setupViews() {
    contentView.addSubview(rectangleView)
    rectangleView.translatesAutoresizingMaskIntoConstraints = false
    rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
    rectangleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
    rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4).isActive = true
    rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4).isActive = true
    rectangleView.layer.cornerRadius = 16
    rectangleView.addSubview(titleLabel)

    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.spacing = 16
    stackView.alignment = .lastBaseline
    stackView.distribution = .equalSpacing

    rectangleView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.topAnchor.constraint(equalTo: rectangleView.topAnchor, constant: 8).isActive = true
    stackView.bottomAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: -8).isActive = true
    stackView.leadingAnchor.constraint(equalTo: rectangleView.leadingAnchor, constant: 16).isActive = true
    stackView.trailingAnchor.constraint(equalTo: rectangleView.trailingAnchor, constant: -16).isActive = true

    stackView.addArrangedSubview(titleLabel)
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true

    stackView.addArrangedSubview(habitsCountLabel)
    habitsCountLabel.font = UIFont.preferredFont(forTextStyle: .body)
    habitsCountLabel.adjustsFontForContentSizeCategory = true

    selectionStyle = .none
  }
}
