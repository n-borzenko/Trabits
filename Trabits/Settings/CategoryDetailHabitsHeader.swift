//
//  CategoryDetailHabitsHeader.swift
//  Trabits
//
//  Created by Natalia Borzenko on 31/07/2023.
//

import UIKit
import Combine

class CategoryDetailHabitsHeader: UITableViewHeaderFooterView {
  static let reuseIdentifier = String(describing: CategoryDetailHabitsHeader.self)

  private let titleLabel = UILabel()
  private let habitsCountLabel = UILabel()
  private let lineView = UIView()

  private var subscriptions: Set<AnyCancellable> = []

  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func fill(with title: String, category: Category) {
    titleLabel.text = "Habits"
    
    category.publisher(for: \.color)
      .assign(to: \.backgroundColor, on: lineView)
      .store(in: &subscriptions)
    category.publisher(for: \.habitsCount)
      .map({ "\($0)" })
      .assign(to: \.text, on: habitsCountLabel)
      .store(in: &subscriptions)
  }

  override func prepareForReuse() {
    for subscription in subscriptions {
      subscription.cancel()
    }
    subscriptions.removeAll()
    
    super.prepareForReuse()
  }
}

extension CategoryDetailHabitsHeader {
  private func setupViews() {
    contentView.addSubview(lineView)
    lineView.translatesAutoresizingMaskIntoConstraints = false
    lineView.heightAnchor.constraint(equalToConstant: 4).isActive = true
    lineView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12).isActive = true
    lineView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6).isActive = true
    lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6).isActive = true

    lineView.layer.cornerRadius = 2

    let stackView = UIStackView()
    contentView.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8).isActive = true
    stackView.bottomAnchor.constraint(equalTo: lineView.topAnchor, constant: -8).isActive = true
    stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20).isActive = true
    stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20).isActive = true

    stackView.axis = .horizontal
    stackView.spacing = 8
    stackView.distribution = .equalSpacing

    titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(habitsCountLabel)
  }
}
