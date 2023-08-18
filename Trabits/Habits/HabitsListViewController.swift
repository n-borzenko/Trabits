//
//  HabitsListViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 09/08/2023.
//

import UIKit

class MyGradientView : UIView {
    override static var layerClass: AnyClass { CAGradientLayer.self }
}

class CategoryListCell: UICollectionViewListCell {
  override func updateConfiguration(using state: UICellConfigurationState) {
    var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)

    //      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    //      backgroundConfiguration.backgroundColor = colors[indexPath.section].withAlphaComponent(0.3)
    //      backgroundConfiguration.strokeColor = colors[indexPath.section]
    //      backgroundConfiguration.strokeWidth = 2
    //      backgroundConfiguration.cornerRadius = 16
    //      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    //      cell.backgroundConfiguration = backgroundConfiguration

    backgroundConfiguration.backgroundColor = .clear

    if state.isHighlighted {
      backgroundConfiguration.backgroundColor = .orange
    }

    if state.isSelected {
      backgroundConfiguration.backgroundColor = .brown
    }

    if state.cellDropState == .targeted {
      backgroundConfiguration.backgroundColor = .red
    }

    if state.cellDragState == .lifting {
      backgroundConfiguration.backgroundColor = .purple
    }

    self.backgroundConfiguration = backgroundConfiguration
  }
}

class HabitListCell: UICollectionViewListCell {
  override func updateConfiguration(using state: UICellConfigurationState) {
    var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell().updated(for: state)

    //      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    //      let view = MyGradientView()
    //      (view.layer as! CAGradientLayer).colors = [
    //        colors[indexPath.section].withAlphaComponent(0.5).cgColor,
    //        UIColor.lightGray.withAlphaComponent(0.5).cgColor
    //      ]
    //      (view.layer as! CAGradientLayer).startPoint = CGPoint(x: 0, y: 0.5)
    //      (view.layer as! CAGradientLayer).endPoint = CGPoint(x: 1, y: 0.5)
    //      backgroundConfiguration.customView = view
    //      backgroundConfiguration.backgroundColor = .purple.withAlphaComponent(0.2)
    //      backgroundConfiguration.cornerRadius = 16
    //      backgroundConfiguration.backgroundInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    //      cell.backgroundConfiguration = backgroundConfiguration

    backgroundConfiguration.backgroundColor = .clear

    if state.isHighlighted {
      backgroundConfiguration.backgroundColor = .orange
    }

    if state.isSelected {
      backgroundConfiguration.backgroundColor = .brown
    }

    if state.cellDragState == .lifting {
      backgroundConfiguration.backgroundColor = .purple
    }

    self.backgroundConfiguration = backgroundConfiguration
  }
}

class HabitsListViewController: UIViewController {
  typealias DataSource = UICollectionViewDiffableDataSource<Int, ItemIdentifier>
  typealias Snapshot = NSDiffableDataSourceSnapshot<Int, ItemIdentifier>

  private var dataSource: DataSource!
  private var safeArea: UILayoutGuide!

  lazy private var collectionView: UICollectionView = {
    UICollectionView(frame: CGRect.zero, collectionViewLayout: createLayout())
  }()

  enum ItemIdentifier: Hashable {
    case category(String)
    case habit(String)
  }

  private var expandedCategories = Set<ItemIdentifier>()

  private var items = [
    [
      ItemIdentifier.category("Group of items #1"),
      ItemIdentifier.habit("Test item 1"),
      ItemIdentifier.habit("Test item 2"),
      ItemIdentifier.habit("Test item 3"),
      ItemIdentifier.habit("Test item 4"),
      ItemIdentifier.habit("Test item 5"),
      ItemIdentifier.habit("Test item 6"),
      ItemIdentifier.habit("Test item 7")
    ],
    [
      ItemIdentifier.category("Group of items #2"),
      ItemIdentifier.habit("Not not test item 1"),
      ItemIdentifier.habit("Not not test item 2"),
      ItemIdentifier.habit("Not not test item 3")
    ],
    [
      ItemIdentifier.category("Group of items #3"),
      ItemIdentifier.habit("Not test item 1"),
      ItemIdentifier.habit("Not test item 2"),
      ItemIdentifier.habit("Not test item 3"),
      ItemIdentifier.habit("Not test item 4"),
      ItemIdentifier.habit("Not test item 5"),
      ItemIdentifier.habit("Not test item 6"),
      ItemIdentifier.habit("Not test item 7")
    ],
    [
      ItemIdentifier.category("Group of items #4")
    ],
    [
      ItemIdentifier.category("Group of items #5"),
      ItemIdentifier.habit("Test Test item 1"),
      ItemIdentifier.habit("Test Test item 2"),
      ItemIdentifier.habit("Test Test item 3")
    ],
  ]
  let colors: [UIColor] = [.blue, .gray, .green, .yellow, .orange]

  init() {
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    applySnapshot()
    collectionView.dataSource = dataSource
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

extension HabitsListViewController {
  private func deleteItem(at indexPath: IndexPath) {
    if indexPath.item == 0 {
      items.remove(at: indexPath.section)
    } else {
      items[indexPath.section].remove(at: indexPath.item)
    }
    applySnapshot()
  }

  private func editCategory(at indexPath: IndexPath) {
    let addCategoryViewController = EditCategoryViewController()
    let navigationViewController = UINavigationController(rootViewController: addCategoryViewController)
    present(navigationViewController, animated: true)
  }

  private func createLayout() -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
    configuration.headerMode = .none
    configuration.showsSeparators = false
    configuration.backgroundColor = .clear
    configuration.footerMode = .none
    configuration.trailingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
      let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {[weak self] action, sourceView, actionPerformed in
        self?.deleteItem(at: indexPath)
        actionPerformed(true)
      }
      deleteAction.image = UIImage(systemName: "trash")

      return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    configuration.leadingSwipeActionsConfigurationProvider = { [unowned self] indexPath in
      guard indexPath.item == 0 else {
        return nil
      }

      let editCategoryAction = UIContextualAction(style: .normal, title: "Edit") {[weak self] action, sourceView, actionPerformed in
        self?.editCategory(at: indexPath)
        actionPerformed(true)
      }
      editCategoryAction.backgroundColor = .green
      editCategoryAction.image = UIImage(systemName: "square.and.pencil")

      return UISwipeActionsConfiguration(actions: [editCategoryAction])
    }
    return UICollectionViewCompositionalLayout.list(using: configuration)
  }

  private func configureDataSource() {
    let categoryCellRegistration = UICollectionView.CellRegistration {
      (cell: CategoryListCell, indexPath: IndexPath, itemIdentifier: ItemIdentifier) in
      guard case let ItemIdentifier.category(item) = itemIdentifier else { return }
      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = item
      cell.contentConfiguration = contentConfiguration

      let options = UICellAccessory.OutlineDisclosureOptions(style: .header)
      cell.accessories = [.outlineDisclosure(options: options)]
    }

    let habitCellRegistration = UICollectionView.CellRegistration {
      (cell: HabitListCell, indexPath: IndexPath, itemIdentifier: ItemIdentifier) in
      guard case let ItemIdentifier.habit(item) = itemIdentifier else { return }
      var contentConfiguration = cell.defaultContentConfiguration()
      contentConfiguration.text = item
      cell.contentConfiguration = contentConfiguration

      cell.accessories = [.disclosureIndicator()]
    }

    dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      switch itemIdentifier {
      case .category(_):
        return collectionView.dequeueConfiguredReusableCell(using: categoryCellRegistration, for: indexPath, item: itemIdentifier)
      case .habit(_):
        return collectionView.dequeueConfiguredReusableCell(using: habitCellRegistration, for: indexPath, item: itemIdentifier)
      }
    }

    dataSource.sectionSnapshotHandlers.willCollapseItem = { [weak self] itemIdentifier in
      self?.expandedCategories.remove(itemIdentifier)
    }

    dataSource.sectionSnapshotHandlers.willExpandItem = { [weak self] itemIdentifier in
      self?.expandedCategories.insert(itemIdentifier)
    }
  }

  private func applySnapshot() {
    var snapshot = Snapshot()
    for index in 0..<items.count {
      snapshot.appendSections([index])
    }
    dataSource.apply(snapshot)

    for index in 0..<items.count {
      var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<ItemIdentifier>()
      let parentItem = items[index][0]
      sectionSnapshot.append([parentItem])
      sectionSnapshot.append(Array(items[index][1..<items[index].count]), to: parentItem)
      if expandedCategories.contains(parentItem) {
        sectionSnapshot.expand([parentItem])
      }
      dataSource.apply(sectionSnapshot, to: index, animatingDifferences: false)
    }
  }

  private func setupViews() {
    safeArea = view.safeAreaLayoutGuide

    view.backgroundColor = .white
    
    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0).isActive = true
    collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0).isActive = true
    collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0).isActive = true
    collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0).isActive = true

    navigationItem.title = "Habits"

    collectionView.dragDelegate = self
    collectionView.dropDelegate = self
    collectionView.dragInteractionEnabled = true
    collectionView.allowsSelection = true
    collectionView.delegate = self
  }
}

extension HabitsListViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//    let category = fetchResultsController.object(at: indexPath)
//    let detailViewController = EditCategoryViewController()
//    navigationController?.pushViewController(detailViewController, animated: true)


    let addCategoryViewController = EditCategoryViewController()
    let navigationViewController = UINavigationController(rootViewController: addCategoryViewController)
    present(navigationViewController, animated: true)
    collectionView.deselectItem(at: indexPath, animated: false)
  }
}

extension HabitsListViewController: UICollectionViewDragDelegate {
  func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    session.localContext = indexPath
    let itemProvider = NSItemProvider(object: "\(indexPath.section)-\(indexPath.item)" as NSString)
    let dragItem = UIDragItem(itemProvider: itemProvider)
    return [dragItem]
  }

  func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
    true
  }
}

extension HabitsListViewController: UICollectionViewDropDelegate {
  func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
    guard coordinator.proposal.operation == .move,
          let item = coordinator.items.first,
          let sourceIndexPath = item.sourceIndexPath else {
      return
    }

    var dropIndexPath: IndexPath

    if sourceIndexPath.item == 0 {
      // category replacement
      let section = items.remove(at: sourceIndexPath.section)
      var sectionIndex: Int
      if let destinationIndexPath = coordinator.destinationIndexPath {
        sectionIndex = sourceIndexPath.section < destinationIndexPath.section ? destinationIndexPath.section - 1 : destinationIndexPath.section
        if destinationIndexPath.item > 0 {
          sectionIndex += 1
        }
        items.insert(section, at: sectionIndex)
      } else {
        sectionIndex = items.count - 1
        items.append(section)
      }
      dropIndexPath = IndexPath(item: 0, section: sectionIndex)
    } else {
      guard let destinationIndexPath = coordinator.destinationIndexPath else {
        return
      }
      // habit replacement
      let itemIdentifier = items[sourceIndexPath.section].remove(at: sourceIndexPath.item)
      items[destinationIndexPath.section].insert(itemIdentifier, at: max(1, destinationIndexPath.item))
      dropIndexPath = destinationIndexPath
    }

    applySnapshot()
    coordinator.drop(item.dragItem, toItemAt: dropIndexPath)
  }

  func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
    guard collectionView == self.collectionView && collectionView.hasActiveDrag,
          let sourceIndexPath = session.localDragSession?.localContext as? IndexPath else {
      return UICollectionViewDropProposal(operation: .forbidden)
    }

    // calculate actual destination indexPath
    let location = session.location(in: collectionView)
    var actualDestinationIndexPath: IndexPath? = nil
    collectionView.performUsingPresentationValues {
      actualDestinationIndexPath = collectionView.indexPathForItem(at: location)
    }

    // category should be always the first item in a section
    if sourceIndexPath.item == 0 {
      // replacement to the end of the list is allowed
      guard let destinationIndexPath = actualDestinationIndexPath else {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
      }

      // category should be the first item in the section
      if destinationIndexPath.item == 0 {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
      }

      // category can be suggested as the last item in the section and should be placed to the next section
      let category = items[destinationIndexPath.section][0]
      let maxItemIndex = expandedCategories.contains(category) ? items[destinationIndexPath.section].count : 1
      if destinationIndexPath.item == maxItemIndex {
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
      }
    }

    if sourceIndexPath.item != 0 {
      guard let destinationIndexPath = destinationIndexPath else {
        return UICollectionViewDropProposal(operation: .forbidden)
      }

      // habit can be inside any section
      // if it is inserted into the category cell, habit will become the first item in the category
      return UICollectionViewDropProposal(
        operation: .move,
        intent: destinationIndexPath.item == 0 ? .insertIntoDestinationIndexPath : .insertAtDestinationIndexPath
      )
    }

    return UICollectionViewDropProposal(operation: .forbidden)
  }

  func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
    session.isRestrictedToDraggingApplication
  }
}
