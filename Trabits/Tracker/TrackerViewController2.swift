//
//  TrackerViewController2.swift
//  Trabits
//
//  Created by Natalia Borzenko on 05/10/2023.
//

import UIKit

class TrackerViewController2: UIViewController {
  
  enum SectionIdentifier: Hashable {
    case date
    case category
  }

  enum ItemIdentifier: Hashable {
    case day(Date)
  }
  
  enum PanGestureDirection {
    case previous
    case next
    case none
  }

  typealias DataSource = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>
  
  private var dataSource: DataSource!
  
  private var monthFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .none
    dateFormatter.dateStyle = .short
    return dateFormatter
  }()
  
  private var selectedDate: Date! {
    didSet {
      navigationItem.title = monthFormatter.string(from: selectedDate)
    }
  }
  
  private var isInitialScrollCompleted = false
  private var isScrollApplied = false
//  private var panGestureDirection = PanGestureDirection.none
  
  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()
  
  private var containerView = UIView()
//  private var child1CenterXConstraint: NSLayoutConstraint!
//  private var child2CenterXConstraint: NSLayoutConstraint?
  
  private var pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
  
  init() {
    super.init(nibName: nil, bundle: nil)
    selectedDate = Calendar.current.startOfDay(for: Date())
    navigationItem.title = monthFormatter.string(from: selectedDate)
    setupViews()
    
    configureDataSource()
    collectionView.delegate = self
    collectionView.dataSource = dataSource
    applySnapshot(middleDate: selectedDate)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    guard !isInitialScrollCompleted else { return }
    Task {
      await MainActor.run {
        let indexPath = dataSource.indexPath(for: ItemIdentifier.day(selectedDate))
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        isInitialScrollCompleted = true
      }
    }
  }
}

extension TrackerViewController2 {
  private func createLayout() -> UICollectionViewCompositionalLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/7), heightDimension: .fractionalHeight(1))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2)
    
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    
    let section = NSCollectionLayoutSection(group: group)
    section.orthogonalScrollingBehavior = .groupPaging
    let configuration = UICollectionViewCompositionalLayoutConfiguration()
    return UICollectionViewCompositionalLayout(section: section, configuration: configuration)
  }

  private func configureDataSource() {
    let dayCellRegistration = UICollectionView.CellRegistration {
      [unowned self] (cell: TrackerDayCell, indexPath: IndexPath, itemIdentifier: ItemIdentifier) in
      guard case let .day(date) = itemIdentifier else { return }
      cell.fill(date: date)
    }

    dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .day(_):
        return collectionView.dequeueConfiguredReusableCell(using: dayCellRegistration, for: indexPath, item: itemIdentifier)
      }
    }
  }
  
  private func applySnapshot(middleDate: Date = Date()) {
    var snapshot = Snapshot()
    snapshot.appendSections([.date])
    
    guard let startOfTheWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: middleDate)) else { return }
    
    let adjustedStartOfTheWeek = Calendar.current.startOfDay(for: startOfTheWeek)
    var days: [ItemIdentifier] = []
    for i in -7..<14 {
      guard let day = Calendar.current.date(byAdding: .day, value: i, to: adjustedStartOfTheWeek) else { continue }
      days.append(ItemIdentifier.day(day))
    }
    
    snapshot.appendItems(days, toSection: .date)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
}

extension TrackerViewController2 {
  private func setupViews() {
    view.backgroundColor = .backgroundColor
    
    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    collectionView.heightAnchor.constraint(equalToConstant: 60).isActive = true
    
    view.addSubview(containerView)
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10).isActive = true
    containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    
    let trailingBorderView = UIView()
    trailingBorderView.backgroundColor = .background
    view.addSubview(trailingBorderView)
    trailingBorderView.translatesAutoresizingMaskIntoConstraints = false
    trailingBorderView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    trailingBorderView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
    trailingBorderView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    trailingBorderView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    let leadingBorderView = UIView()
    leadingBorderView.backgroundColor = .background
    view.addSubview(leadingBorderView)
    leadingBorderView.translatesAutoresizingMaskIntoConstraints = false
    leadingBorderView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    leadingBorderView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    leadingBorderView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
    leadingBorderView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    
    navigationItem.largeTitleDisplayMode = .never
    collectionView.alwaysBounceVertical = false
    
    
    pageViewController.delegate = self
    pageViewController.dataSource = self
    
    addChild(pageViewController)
    containerView.addPinnedSubview(pageViewController.view)

    let initialListController = TrackerListViewController(date: selectedDate)
    pageViewController.setViewControllers([initialListController], direction: .forward, animated: false)
    
    pageViewController.didMove(toParent: self)
  }
}

extension TrackerViewController2: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath),
          case let .day(date) = itemIdentifier else { return }
    
    let direction: UIPageViewController.NavigationDirection = date > selectedDate ? .forward : .reverse
    selectedDate = date
    let currentListController = TrackerListViewController(date: selectedDate)
    pageViewController.setViewControllers([currentListController], direction: direction, animated: true)
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard isInitialScrollCompleted, indexPath.section == 0 else { return }
    
    guard !isScrollApplied, indexPath.item == 0 || indexPath.item == 20 else { return }
    let adjustment = indexPath.item == 0 ? -7 : 7
    
    guard let date = Calendar.current.date(byAdding: .day, value: adjustment, to: selectedDate) else { return }
    isScrollApplied = true
    selectedDate = date
    applySnapshot(middleDate: date)
    print(selectedDate)
    
    if let controller = pageViewController.viewControllers?.first as? TrackerListViewController,
       controller.date != selectedDate {
      let currentListController = TrackerListViewController(date: selectedDate)
      pageViewController.setViewControllers([currentListController], direction: adjustment > 0 ? .forward : .reverse, animated: true)
    }
    
    let selectedIndexPath = dataSource.indexPath(for: ItemIdentifier.day(selectedDate))
    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
    isScrollApplied = false
  }
}

extension TrackerViewController2: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
    guard let controller = pageViewController.viewControllers?.first as? TrackerListViewController,
          completed else { return }
    
    guard let indexPath = dataSource.indexPath(for: ItemIdentifier.day(controller.date)) else { return }
    
    if indexPath.item >= 7 && indexPath.item < 14 {
      selectedDate = controller.date
      collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    } else if indexPath.item < 7 {
      selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: controller.date)
      collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//      collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    } else {
      selectedDate = Calendar.current.date(byAdding: .day, value: -7, to: controller.date)
      collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
  }
}

extension TrackerViewController2: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else {
      return nil
    }
    return TrackerListViewController(date: newDate)
  }
  
  func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else {
      return nil
    }
    return TrackerListViewController(date: newDate)
  }
}
