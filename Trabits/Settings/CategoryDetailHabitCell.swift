//
//  CategoryDetailHabitCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/07/2023.
//

import UIKit
import Combine

class CategoryDetailHabitCell: UITableViewCell {
  static let reuseIdentifier = String(describing: CategoryDetailHabitCell.self)

  private let titleLabel = UILabel()
  private let rectangleView = UIView()

  private var subscriptions: Set<AnyCancellable> = []

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    for subscription in subscriptions {
      subscription.cancel()
    }
    subscriptions.removeAll()

    super.prepareForReuse()
  }

  func fill(with habit: Habit) {
    titleLabel.text = habit.title

    habit.category?.publisher(for: \.color)
      .map { $0?.cgColor }
      .assign(to: \.layer.borderColor, on: rectangleView)
      .store(in: &subscriptions)
  }
}

extension CategoryDetailHabitCell {
  private func setupViews() {
    contentView.addSubview(rectangleView)
    rectangleView.translatesAutoresizingMaskIntoConstraints = false
    rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4).isActive = true
    rectangleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4).isActive = true
    rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4).isActive = true
    rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4).isActive = true

    rectangleView.layer.cornerRadius = 16
    rectangleView.layer.borderWidth = 2

    rectangleView.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.topAnchor.constraint(equalTo: rectangleView.topAnchor, constant: 8).isActive = true
    titleLabel.bottomAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: -8).isActive = true
    titleLabel.leadingAnchor.constraint(equalTo: rectangleView.leadingAnchor, constant: 16).isActive = true
    titleLabel.trailingAnchor.constraint(equalTo: rectangleView.trailingAnchor, constant: -16).isActive = true

    selectionStyle = .none
  }
}
