//
//  TrackerDayCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 28/09/2023.
//

import UIKit

class TrackerDayContentView: UIView, UIContentView {
  private var currentConfiguration: TrackerDayContentConfiguration!
  var configuration: UIContentConfiguration {
    get { currentConfiguration }
    set {
      guard let newConfiguration = newValue as? TrackerDayContentConfiguration else { return }
      apply(configuration: newConfiguration)
    }
  }

  private let weekdayLabel = UILabel()
  private let dayLabel = UILabel()
  
  static let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd"
    return formatter
  }()
  
  static let weekdayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEEEE"
    return formatter
  }()

  init(configuration: TrackerDayContentConfiguration) {
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
    stackView.distribution = .equalCentering
    stackView.alignment = .center
    addPinnedSubview(stackView, flexibleBottom: true)

    weekdayLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
    weekdayLabel.adjustsFontForContentSizeCategory = true
    weekdayLabel.textColor = .secondaryLabel
    weekdayLabel.textAlignment = .center
    stackView.addArrangedSubview(weekdayLabel)

    dayLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    dayLabel.adjustsFontForContentSizeCategory = true
    dayLabel.textAlignment = .center
    stackView.addArrangedSubview(dayLabel)
    dayLabel.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.6).isActive = true
    let widthConstraint = dayLabel.widthAnchor.constraint(equalTo: dayLabel.heightAnchor, multiplier: 1.0)
    widthConstraint.priority = .defaultHigh
    widthConstraint.isActive = true

    dayLabel.layer.cornerRadius = (bounds.height * 0.6) / 2
  }

  func apply(configuration: TrackerDayContentConfiguration) {
    guard configuration != currentConfiguration else { return }
    currentConfiguration = configuration
    
    dayLabel.text = TrackerDayContentView.dayFormatter.string(from: configuration.date)
    weekdayLabel.text = TrackerDayContentView.weekdayFormatter.string(from: configuration.date)
    
    weekdayLabel.textColor = .contrastColor
    
    if configuration.isToday {
      dayLabel.textColor = configuration.isSelected ? .background : .themeColor
      dayLabel.layer.backgroundColor = configuration.isSelected ? UIColor.themeColor.cgColor : UIColor.secondarySystemBackground.cgColor
    } else {
      dayLabel.textColor = configuration.isSelected ? .background : .contrastColor
      dayLabel.layer.backgroundColor = configuration.isSelected ? UIColor.contrastColor.cgColor : UIColor.secondarySystemBackground.cgColor
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      if currentConfiguration.isToday {
        dayLabel.layer.backgroundColor = currentConfiguration.isSelected ? UIColor.themeColor.cgColor : UIColor.secondarySystemBackground.cgColor
      } else {
        dayLabel.layer.backgroundColor = currentConfiguration.isSelected ? UIColor.contrastColor.cgColor : UIColor.secondarySystemBackground.cgColor
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    dayLabel.layer.cornerRadius = (bounds.height * 0.6) / 2
  }
}

struct TrackerDayContentConfiguration: UIContentConfiguration, Hashable {
  var date = Date()
  var isSelected: Bool = false
  var isToday: Bool = false

  func makeContentView() -> UIView & UIContentView {
    return TrackerDayContentView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> TrackerDayContentConfiguration {
    guard let state = state as? UICellConfigurationState else { return self }
    
    var configuration = self
    configuration.isSelected = state.isSelected
    return configuration
  }
}

class TrackerDayCell: UICollectionViewListCell {
  private var date = Date()

  func fill(date: Date) {
    self.date = date
    setNeedsUpdateConfiguration()
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    var newConfiguration = TrackerDayContentConfiguration().updated(for: state)

    newConfiguration.date = date
    newConfiguration.isToday = Calendar.current.isDateInToday(date)

    contentConfiguration = newConfiguration
    backgroundConfiguration = UIBackgroundConfiguration.clear()
  }
}
