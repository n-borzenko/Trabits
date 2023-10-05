//
//  TrackerViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 28/09/2023.
//

import UIKit

class TrackerViewController: UIViewController {
  
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
  private var panGestureDirection = PanGestureDirection.none
  
  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()
  
  private var containerView = UIView()
  private var child1CenterXConstraint: NSLayoutConstraint!
  private var child2CenterXConstraint: NSLayoutConstraint?
  
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
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    Task {
      await MainActor.run {
        let indexPath = dataSource.indexPath(for: ItemIdentifier.day(selectedDate))
        collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        isInitialScrollCompleted = true
      }
    }
  }
}

extension TrackerViewController {
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
    
    var days: [ItemIdentifier] = []
    for i in -7..<14 {
      guard let day = Calendar.current.date(byAdding: .day, value: i, to: startOfTheWeek) else { continue }
      days.append(ItemIdentifier.day(day))
    }
    
    snapshot.appendItems(days, toSection: .date)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
}

extension TrackerViewController {
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
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureHandler))
    containerView.addGestureRecognizer(panGestureRecognizer)
    
//    let leftSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipeGestureHandler))
//    leftSwipeGestureRecognizer.direction = .left
//    containerView.addGestureRecognizer(leftSwipeGestureRecognizer)
//    
//    let rightSwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(rightSwipeGestureHandler))
//    rightSwipeGestureRecognizer.direction = .right
//    containerView.addGestureRecognizer(rightSwipeGestureRecognizer)
    
    navigationItem.largeTitleDisplayMode = .never
    collectionView.alwaysBounceVertical = false
    
    addChildViewController(date: selectedDate, childCenterXConstraint: &child1CenterXConstraint)
  }
  
  private func addChildViewController(date: Date, childCenterXConstraint: inout NSLayoutConstraint!) {
    let childController = TrackerListViewController(date: date)
    addChild(childController)
    containerView.addSubview(childController.view)
    childController.view.translatesAutoresizingMaskIntoConstraints = false
    childController.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
    childController.view.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
    childController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    childCenterXConstraint = childController.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 0)
    childCenterXConstraint.isActive = true
    childController.didMove(toParent: self)
  }
  
  private func removeChildViewController(at index: Int = 0) {
    guard index < children.count else { return }
    
    let childController = children[index]
    childController.willMove(toParent: nil)
    childController.view.removeFromSuperview()
    childController.removeFromParent()
  }
  
//  @objc private func leftSwipeGestureHandler(_ sender: UISwipeGestureRecognizer) {
//    guard let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
//    
//    addChildViewController(date: newDate, childCenterXConstraint: &child2CenterXConstraint)
//    child2CenterXConstraint?.constant = containerView.frame.width
//    
//    Task {
//      await MainActor.run {
//        UIView.animate(withDuration: 1, delay: 0.25, animations: { [weak self] in
//          guard let self else { return }
//          child1CenterXConstraint.constant = -containerView.frame.width
//          child2CenterXConstraint?.constant = 0
//        }, completion: { [weak self] _ in
//          guard let self else { return }
//          removeChildViewController(at: 0)
//          child1CenterXConstraint = child2CenterXConstraint
//          selectedDate = newDate
//          child2CenterXConstraint = nil
//          panGestureDirection = .none
//        })
//      }
//    }
//  }
//  
//  @objc private func rightSwipeGestureHandler(_ sender: UISwipeGestureRecognizer) {
//    
//  }
  
  @objc private func panGestureHandler(_ sender: UIPanGestureRecognizer) {
    switch sender.state {
    case .began:
      let velocity = sender.velocity(in: containerView)
      let point = sender.translation(in: containerView)
//      guard abs(point.x) > abs(point.y) else {
//        panGestureDirection = .none
//        return
//      }

      panGestureDirection = velocity.x > 0 ? .previous : .next
      print(panGestureDirection == .previous)
      let dayOffset = panGestureDirection == .previous ? -1 : 1
      guard let newDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedDate) else {
        panGestureDirection = .none
        return
      }
      
      addChildViewController(date: newDate, childCenterXConstraint: &child2CenterXConstraint)
      child1CenterXConstraint.constant = point.x
      if panGestureDirection == .previous {
        child2CenterXConstraint?.constant = -containerView.frame.width + point.x
      } else {
        child2CenterXConstraint?.constant = containerView.frame.width + point.x
      }
    case .changed:
      guard panGestureDirection != .none else { return }
      let x = sender.translation(in: containerView).x
      child1CenterXConstraint.constant = x
      if panGestureDirection == .previous {
        child2CenterXConstraint?.constant = -containerView.frame.width + x
      } else {
        child2CenterXConstraint?.constant = containerView.frame.width + x
      }
    case .ended:
      guard panGestureDirection != .none else { return }
      let x = sender.translation(in: containerView).x
      let containerWidth = containerView.frame.width
      let velocity = sender.velocity(in: containerView).x
      let isHalfScreenPassed = (containerWidth / 2) <= abs(x)
      
      let isGestureCompleted =
        isHalfScreenPassed && panGestureDirection == .next ||
        !isHalfScreenPassed && velocity < -500 && panGestureDirection == .next ||
        isHalfScreenPassed && panGestureDirection == .previous ||
        !isHalfScreenPassed && velocity > 500 && panGestureDirection == .previous
      
      print(isHalfScreenPassed, velocity, isGestureCompleted)
        
      if isGestureCompleted {
        child1CenterXConstraint.constant = panGestureDirection == .previous ? containerWidth : -containerWidth
        child2CenterXConstraint?.constant = 0
      } else {
        child1CenterXConstraint.constant = 0
        if panGestureDirection == .previous {
          child2CenterXConstraint?.constant = -containerWidth
        } else {
          child2CenterXConstraint?.constant = containerWidth
        }
      }
      
      UIView.animate(withDuration: 0.25, animations: { [weak self] in
        guard let self else { return }
        containerView.layoutIfNeeded()
      }, completion: { [weak self] _ in
        guard let self else { return }
        if isGestureCompleted {
          removeChildViewController(at: 0)
          child1CenterXConstraint = child2CenterXConstraint
          
          let dayOffset = panGestureDirection == .previous ? -1 : 1
          selectedDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedDate)
        } else {
          removeChildViewController(at: 1)
        }
        child2CenterXConstraint = nil
        panGestureDirection = .none
      })
    default:
      return
    }
  }
}

extension TrackerViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath),
          case let .day(date) = itemIdentifier else { return }
    
    selectedDate = date
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard isInitialScrollCompleted, indexPath.section == 0 else { return }
    
    guard !isScrollApplied, indexPath.item == 0 || indexPath.item == 20 else { return }
    let adjustment = indexPath.item == 0 ? -7 : 7
    
    guard let date = Calendar.current.date(byAdding: .day, value: adjustment, to: selectedDate) else { return }
    isScrollApplied = true
    selectedDate = date
    applySnapshot(middleDate: selectedDate)
    
    let selectedIndexPath = dataSource.indexPath(for: ItemIdentifier.day(selectedDate))
    collectionView.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredHorizontally)
    isScrollApplied = false
  }
}
