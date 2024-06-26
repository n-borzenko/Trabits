//
//  TrackerWeekViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/10/2023.
//

import UIKit
import Combine

class TrackerWeekAccessibilityContainerView: UIView {
  private let dataProvider: TrackerDataProvider
  private let collectionView: UICollectionView

  init(dataProvider: TrackerDataProvider, collectionView: UICollectionView) {
    self.dataProvider = dataProvider
    self.collectionView = collectionView
    super.init(frame: .zero)
    setupViews()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    addPinnedSubview(collectionView)
    isAccessibilityElement = true
    accessibilityTraits = .adjustable
    accessibilityLabel = "Day selector"
    accessibilityHint = "Swipe left or right with three fingers to choose different week"
  }

  override var accessibilityValue: String? {
    get { dataProvider.generateSelectedDateDescription() }
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
    guard let date = Calendar.current.date(byAdding: .day, value: 1, to: dataProvider.selectedDate) else { return }
    dataProvider.selectedDate = date
  }

  override func accessibilityDecrement() {
    guard let date = Calendar.current.date(byAdding: .day, value: -1, to: dataProvider.selectedDate) else { return }
    dataProvider.selectedDate = date
  }

  override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
    let offset = switch direction {
    case .left: 7
    case .right: -7
    default: 0
    }

    guard offset != 0, let date = Calendar.current.date(
      byAdding: .day, value: offset, to: dataProvider.selectedDate
    ) else { return false }
    dataProvider.selectedDate = date
    let weekDirection = direction == .left ? "Next" : "Previous"
    let announcement = "\(weekDirection) week, \(dataProvider.generateSelectedDateDescription())"
    UIAccessibility.post(notification: .pageScrolled, argument: announcement)
    return true
  }
}

class TrackerWeekViewController: UIViewController {
  private enum SectionIdentifier {
    case main
  }
  private typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, Date>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, Date>

  private var dataSource: DataSource!
  private let dataProvider: TrackerDataProvider

  private var startOfTheWeek: Date

  private var cancellable: AnyCancellable?

  private var accessibilityContainerView: TrackerWeekAccessibilityContainerView!

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  init(dataProvider: TrackerDataProvider) {
    self.dataProvider = dataProvider
    self.startOfTheWeek = Calendar.current.startOfTheWeek(for: dataProvider.selectedDate) ?? dataProvider.selectedDate
    super.init(nibName: nil, bundle: nil)
    setupViews()

    configureDataSource()
    collectionView.delegate = self
    collectionView.dataSource = dataSource
    applySnapshot()

    cancellable = dataProvider.$selectedDate.sink { [weak self] newSelectedDate in
      self?.selectedDateUpdateHandler(selectedDate: newSelectedDate)
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard let indexPath = dataSource.indexPath(for: dataProvider.selectedDate) else { return }
    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
    UIAccessibility.post(notification: .screenChanged, argument: accessibilityContainerView)
  }

  deinit {
    cancellable?.cancel()
    cancellable = nil
  }
}

extension TrackerWeekViewController {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/7), heightDimension: .fractionalHeight(1))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2)

    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

    let section = NSCollectionLayoutSection(group: group)
    let configuration = UICollectionViewCompositionalLayoutConfiguration()
    configuration.scrollDirection = .horizontal
    return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
  }

  private func configureDataSource() {
    let dayCellRegistration = UICollectionView.CellRegistration<TrackerWeekDayCell, Date> { cell, _, date in
      cell.fill(date: date)
    }

    dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, date in
      collectionView.dequeueConfiguredReusableCell(using: dayCellRegistration, for: indexPath, item: date)
    }
  }

  private func applySnapshot() {
    var snapshot = Snapshot()
    snapshot.appendSections([.main])
    let days = (-7..<14).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfTheWeek) }
    snapshot.appendItems(days)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
}

extension TrackerWeekViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let date = dataSource.itemIdentifier(for: indexPath) else { return }
    dataProvider.selectedDate = date
  }
}

extension TrackerWeekViewController: UIScrollViewDelegate {
  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      updateWeekSelection()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateWeekSelection()
  }

  func updateWeekSelection() {
    var offset = 0
    if collectionView.contentOffset.x < collectionView.frame.width {
      offset = -7
    } else if collectionView.contentOffset.x >= collectionView.frame.width * 2 {
      offset = 7
    }
    let date = Calendar.current.date(byAdding: .day, value: offset, to: dataProvider.selectedDate)

    guard offset != 0, let date else { return }
    dataProvider.selectedDate = date
  }
}

extension TrackerWeekViewController {
  private func setupViews() {
    accessibilityContainerView = TrackerWeekAccessibilityContainerView(
      dataProvider: dataProvider,
      collectionView: collectionView
    )
    view.addPinnedSubview(accessibilityContainerView)
    collectionView.isPagingEnabled = true
    collectionView.delegate = self
    collectionView.showsHorizontalScrollIndicator = false

    collectionView.addInteraction(UILargeContentViewerInteraction(delegate: self))
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)

    coordinator.animate(alongsideTransition: nil) { [weak self] _ in
      guard let self, let indexPath = dataSource.indexPath(for: dataProvider.selectedDate) else { return }
      collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
    }
  }
}

extension TrackerWeekViewController {
  func selectedDateUpdateHandler(selectedDate: Date) {
    startOfTheWeek = Calendar.current.startOfTheWeek(for: selectedDate) ?? selectedDate
    applySnapshot()

    guard let indexPath = dataSource.indexPath(for: selectedDate) else { return }
    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
  }
}

extension TrackerWeekViewController: UILargeContentViewerInteractionDelegate {
  func largeContentViewerInteraction(
    _ interaction: UILargeContentViewerInteraction,
    didEndOn item: UILargeContentViewerItem?, at point: CGPoint
  ) {
    guard let indexPath = collectionView.indexPathForItem(at: point),
          let date = dataSource.itemIdentifier(for: indexPath) else { return }
    dataProvider.selectedDate = date
  }
}
