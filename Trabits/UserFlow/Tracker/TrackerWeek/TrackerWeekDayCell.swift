//
//  TrackerWeekDayCell.swift
//  Trabits
//
//  Created by Natalia Borzenko on 28/09/2023.
//

import UIKit

class TrackerWeekDayContentView: UIView, UIContentView {
  private var currentConfiguration: TrackerWeekDayContentConfiguration!
  var configuration: UIContentConfiguration {
    get { currentConfiguration }
    set {
      guard let newConfiguration = newValue as? TrackerWeekDayContentConfiguration else { return }
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

  static let fullDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    return formatter
  }()

  init(configuration: TrackerWeekDayContentConfiguration) {
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
    weekdayLabel.maximumContentSizeCategory = .extraExtraExtraLarge
    weekdayLabel.textColor = .secondaryLabel
    weekdayLabel.textAlignment = .center
    stackView.addArrangedSubview(weekdayLabel)

    dayLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    dayLabel.adjustsFontForContentSizeCategory = true
    dayLabel.maximumContentSizeCategory = .extraExtraExtraLarge
    dayLabel.textAlignment = .center
    dayLabel.layer.masksToBounds = true
    dayLabel.layer.borderWidth = 1
    stackView.addArrangedSubview(dayLabel)

    dayLabel.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: 0.6).isActive = true
    let widthConstraint = dayLabel.widthAnchor.constraint(equalTo: dayLabel.heightAnchor, multiplier: 1.0)
    widthConstraint.priority = .defaultHigh
    widthConstraint.isActive = true

    showsLargeContentViewer = true
  }

  func apply(configuration: TrackerWeekDayContentConfiguration) {
    guard configuration != currentConfiguration else { return }
    currentConfiguration = configuration

    largeContentTitle = TrackerWeekDayContentView.fullDayFormatter.string(from: configuration.date)
    dayLabel.text = TrackerWeekDayContentView.dayFormatter.string(from: configuration.date)
    weekdayLabel.text = TrackerWeekDayContentView.weekdayFormatter.string(from: configuration.date)

    dayLabel.textColor = configuration.isSelected ? .inverted : .label
    if configuration.isToday {
      dayLabel.backgroundColor = configuration.isSelected ? .contrast : .neutral5
      dayLabel.layer.borderColor = UIColor.contrast.cgColor
    } else {
      dayLabel.backgroundColor = configuration.isSelected ? .neutral70 : .neutral5
      dayLabel.layer.borderColor = UIColor.clear.cgColor
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      if currentConfiguration.isToday {
        dayLabel.backgroundColor = currentConfiguration.isSelected ? .contrast : .neutral5
        dayLabel.layer.borderColor = UIColor.contrast.cgColor
      } else {
        dayLabel.backgroundColor = currentConfiguration.isSelected ? .neutral70 : .neutral5
        dayLabel.layer.borderColor = UIColor.clear.cgColor
      }
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    dayLabel.layer.cornerRadius = (bounds.height * 0.6) / 2
  }
}

struct TrackerWeekDayContentConfiguration: UIContentConfiguration, Hashable {
  var date = Date()
  var isSelected: Bool = false
  var isToday: Bool = false

  func makeContentView() -> UIView & UIContentView {
    return TrackerWeekDayContentView(configuration: self)
  }

  func updated(for state: UIConfigurationState) -> TrackerWeekDayContentConfiguration {
    guard let state = state as? UICellConfigurationState else { return self }

    var configuration = self
    configuration.isSelected = state.isSelected
    return configuration
  }
}

class TrackerWeekDayCell: UICollectionViewCell {
  private var date = Date()

  func fill(date: Date) {
    self.date = date
    setNeedsUpdateConfiguration()
  }

  override func updateConfiguration(using state: UICellConfigurationState) {
    var newConfiguration = TrackerWeekDayContentConfiguration().updated(for: state)

    newConfiguration.date = date
    newConfiguration.isToday = Calendar.current.isDateInToday(date)

    contentConfiguration = newConfiguration
    backgroundConfiguration = UIBackgroundConfiguration.clear()
  }
}
