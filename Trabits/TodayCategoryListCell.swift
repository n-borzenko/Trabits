//
//  TodayCategoryListCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 21/09/2023.
//

import UIKit

class TodayCategoryContentView: UIView, UIContentView {
  private var currentConfiguration: TodayCategoryContentConfiguration!
  var configuration: UIContentConfiguration {
    get { currentConfiguration }
    set {
      guard let newConfiguration = newValue as? TodayCategoryContentConfiguration else { return }
      apply(configuration: newConfiguration)
    }
  }

  private let titleLabel = UILabel()
  private let progressLabel = UILabel()
  private let progressView = UIProgressView()

  init(configuration: TodayCategoryContentConfiguration) {
    super.init(frame: .zero)
    setupViews()
    apply(configuration: configuration)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .fill
    stackView.spacing = 8
    addPinnedSubview(stackView, insets: UIEdgeInsets(top: 16, left: 8, bottom: 8, right: 8), layoutGuide: safeAreaLayoutGuide, flexibleBottom: true)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 0
    stackView.addArrangedSubview(titleLabel)

    progressLabel.translatesAutoresizingMaskIntoConstraints = false
    progressLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    progressLabel.adjustsFontForContentSizeCategory = true
    progressLabel.textColor = .secondaryLabel
    stackView.addArrangedSubview(progressLabel)

    progressView.translatesAutoresizingMaskIntoConstraints = false
    progressView.heightAnchor.constraint(equalToConstant: 8).isActive = true
    progressView.layer.sublayers?.last?.borderColor = UIColor.contrastColor.cgColor
    progressView.layer.sublayers?.last?.borderWidth = 1
    progressView.layer.sublayers?.last?.cornerRadius = 4
    progressView.layer.sublayers?.first?.cornerRadius = 4
    stackView.addArrangedSubview(progressView)
  }

  func apply(configuration: TodayCategoryContentConfiguration) {
    guard configuration != currentConfiguration else { return }
    currentConfiguration = configuration

    titleLabel.text = configuration.title
    progressLabel.text = "\(configuration.progressCount) of \(configuration.totalCount)"
    progressView.progress = Float(configuration.progressCount) / Float(configuration.totalCount)
    progressView.progressTintColor = configuration.color
    progressView.trackTintColor = configuration.color.withAlphaComponent(0.7)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      progressView.layer.sublayers?.last?.borderColor = UIColor.contrastColor.cgColor
    }
  }
}

struct TodayCategoryContentConfiguration: UIContentConfiguration, Hashable {
  var title: String = ""
  var progressCount: Int = 0
  var totalCount: Int = 0
  var color: UIColor = .clear

  func makeContentView() -> UIView & UIContentView {
    return TodayCategoryContentView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> TodayCategoryContentConfiguration {
    return self
  }
}

class TodayCategoryListCell: UICollectionViewListCell {
  private var category: Category?
  private var completedHabitsCount: Int = 0

  func fill(category: Category, completedHabitsCount: Int) {
    self.category = category
    self.completedHabitsCount = completedHabitsCount

    setNeedsUpdateConfiguration()
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    var newConfiguration = TodayCategoryContentConfiguration().updated(for: state)

    newConfiguration.title = category?.title ?? ""
    newConfiguration.totalCount = category?.habits?.count ?? 0
    newConfiguration.progressCount = completedHabitsCount
    newConfiguration.color = category?.color ?? .systemGray6

    contentConfiguration = newConfiguration
  }
}
