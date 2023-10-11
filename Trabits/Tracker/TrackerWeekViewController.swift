//
//  TrackerWeekViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 07/10/2023.
//

import UIKit
import Combine

class TrackerWeekViewController: UIViewController {
  private enum SectionIdentifier {
    case main
  }
  private typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, Date>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, Date>
  
  private var dataSource: DataSource!
  private let dataProvider: TrackerDataProvider
  
  private var cancellable: AnyCancellable?
  
  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()
  
  let startOfTheWeek: Date
  
  init(dataProvider: TrackerDataProvider, startOfTheWeek: Date) {
    self.dataProvider = dataProvider
    self.startOfTheWeek = startOfTheWeek
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
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    selectedDateUpdateHandler(selectedDate: dataProvider.selectedDate)
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
    let dayCellRegistration = UICollectionView.CellRegistration<TrackerDayCell, Date> { cell, indexPath, date in
      cell.fill(date: date)
    }

    dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, date in
      collectionView.dequeueConfiguredReusableCell(using: dayCellRegistration, for: indexPath, item: date)
    }
  }
  
  private func applySnapshot() {
    var snapshot = Snapshot()
    snapshot.appendSections([.main])
    let days = (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: startOfTheWeek) }
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

extension TrackerWeekViewController {
  private func setupViews() {
    view.addPinnedSubview(collectionView)
    collectionView.alwaysBounceVertical = false
  }
}

extension TrackerWeekViewController {
  func selectedDateUpdateHandler(selectedDate: Date) {
    guard let indexPath = dataSource.indexPath(for: selectedDate) else { return }
    collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
  }
}
