//
//  CategoryDetailCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 30/07/2023.
//

import UIKit
import Combine

protocol CategoryDetailCellDelegate: AnyObject {
  func editCategory()
}

class CategoryDetailCell: UITableViewCell {
  static let reuseIdentifier = String(describing: CategoryDetailCell.self)

  private let titleLabel = UILabel()
  private let editButton = UIButton(type: .roundedRect)
  private let rectangleView = UIView()

  private var subscriptions: Set<AnyCancellable> = []

  weak var delegate: CategoryDetailCellDelegate?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func fill(with category: Category) {
    category.publisher(for: \.title)
      .assign(to: \.text, on: titleLabel)
      .store(in: &subscriptions)
    category.publisher(for: \.color)
      .assign(to: \.backgroundColor, on: rectangleView)
      .store(in: &subscriptions)
  }

  override func prepareForReuse() {
    for subscription in subscriptions {
      subscription.cancel()
    }
    subscriptions.removeAll()

    super.prepareForReuse()
  }

  @objc func editButtonTapped() {
    self.delegate?.editCategory()
  }
}

extension CategoryDetailCell {
  private func setupViews() {
    contentView.addSubview(rectangleView)
    rectangleView.translatesAutoresizingMaskIntoConstraints = false
    rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
    rectangleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
    rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4).isActive = true
    rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4).isActive = true

    rectangleView.layer.cornerRadius = 16

    let stackView = UIStackView()
    rectangleView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.topAnchor.constraint(equalTo: rectangleView.topAnchor, constant: 8).isActive = true
    stackView.bottomAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: -8).isActive = true
    stackView.leadingAnchor.constraint(equalTo: rectangleView.leadingAnchor, constant: 16).isActive = true
    stackView.trailingAnchor.constraint(equalTo: rectangleView.trailingAnchor, constant: -16).isActive = true

    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.distribution = .equalSpacing
    stackView.alignment = .fill

    stackView.addArrangedSubview(titleLabel)
    titleLabel.numberOfLines = 0
    titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
    titleLabel.adjustsFontForContentSizeCategory = true

    let buttonWrapper = UIStackView()
    stackView.addArrangedSubview(buttonWrapper)
    buttonWrapper.translatesAutoresizingMaskIntoConstraints = false
    buttonWrapper.axis = .horizontal
    buttonWrapper.distribution = .equalCentering

    buttonWrapper.addArrangedSubview(UIView(frame: CGRect.zero))
    buttonWrapper.addArrangedSubview(editButton)
    editButton.setTitle("Edit category", for: .normal)
    editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    editButton.tintColor = .black
    editButton.backgroundColor = .white
    editButton.layer.cornerRadius = 8
    editButton.widthAnchor.constraint(equalTo: buttonWrapper.widthAnchor, multiplier: 0.6).isActive = true
    buttonWrapper.addArrangedSubview(UIView(frame: CGRect.zero))
    editButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    editButton.titleLabel?.adjustsFontForContentSizeCategory = true
    editButton.titleLabel?.lineBreakMode = .byTruncatingTail
    editButton.titleLabel?.numberOfLines = 1

    selectionStyle = .none
  }
}
