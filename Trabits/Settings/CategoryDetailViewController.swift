//
//  CategoryDetailViewController.swift
//  Trabits
//
//  Created by Natalia Borzenko on 24/07/2023.
//

import UIKit
import CoreData

class CategoryDetailViewController: UIViewController {
  private let context = (UIApplication.shared.delegate as! AppDelegate).coreDataStack.persistentContainer.viewContext

  private var category: Category
  private var fetchResultsController: NSFetchedResultsController<Habit>!
  private var dataSource: CategoryDetailDataSource!
  private let tableView = UITableView()
  private let editHabitsBarButton = UIBarButtonItem(title: "Edit Habits")

  init(category: Category) {
    self.category = category
    super.init(nibName: nil, bundle: nil)
    setupViews()
    configureDataSource()
    applySnapshot()
    configureFetchedResultsController()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func addHabit() {
    let addHabitViewController = EditHabitViewController(category: category)
    let navigationViewController = UINavigationController(rootViewController: addHabitViewController)
    present(navigationViewController, animated: true)
  }

  @objc private func editHabits() {
    tableView.isEditing.toggle()
    editHabitsBarButton.title = tableView.isEditing ? "Done" : "Edit Habits"
  }
}

enum CategoryDetailTableViewSection: String {
  case category
  case habits
}

enum CategoryDetailTableViewItem: Hashable {
  case category(Category)
  case habit(NSManagedObjectID)
}

protocol CategoryDetailDataSourceDelegate {
  func deleteHabit(at indexPath: IndexPath)
  func moveHabit(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
}

extension CategoryDetailViewController: CategoryDetailDataSourceDelegate {
  func deleteHabit(at indexPath: IndexPath) {
    let habit = fetchResultsController.object(at: indexPath)
    let itemsCount = (fetchResultsController.sections?[0].numberOfObjects ?? 0)
    for i in (indexPath.row + 1)..<itemsCount {
      let item = fetchResultsController.object(at: IndexPath(row: i, section: 0))
      item.orderPriority -= 1
    }

    context.delete(habit)

    do {
      try context.save()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }

  func moveHabit(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let habit = fetchResultsController.object(at: sourceIndexPath)
    habit.orderPriority = destinationIndexPath.row

    if sourceIndexPath.row < destinationIndexPath.row {
      for i in (sourceIndexPath.row + 1)...(destinationIndexPath.row) {
        let item = fetchResultsController.object(at: IndexPath(row: i, section: 0))
        item.orderPriority -= 1
      }
    } else {
      for i in (destinationIndexPath.row)..<(sourceIndexPath.row) {
        let item = fetchResultsController.object(at: IndexPath(row: i, section: 0))
        item.orderPriority += 1
      }
    }

    Task {
      do {
        try context.save()
      } catch {
        let nserror = error as NSError
        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
      }
    }
  }
}

class CategoryDetailDataSource: UITableViewDiffableDataSource<CategoryDetailTableViewSection, CategoryDetailTableViewItem> {
  var delegate: CategoryDetailDataSourceDelegate?

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    indexPath.section != 0
  }

  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    indexPath.section != 0
  }

  override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    delegate?.moveHabit(
      at: IndexPath(row: sourceIndexPath.row, section: 0),
      to: IndexPath(row: destinationIndexPath.row, section: 0)
    )
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      delegate?.deleteHabit(at: IndexPath(row: indexPath.row, section: 0))
    }
  }
}

extension CategoryDetailViewController: NSFetchedResultsControllerDelegate {
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {

    let fetchedSnapshot = snapshot as NSDiffableDataSourceSnapshot<AnyHashable, NSManagedObjectID>
    var currentSnapshot = dataSource.snapshot()

    let items = fetchedSnapshot.itemIdentifiers.map { CategoryDetailTableViewItem.habit($0) }
    currentSnapshot.deleteItems(currentSnapshot.itemIdentifiers(inSection: .habits))
    currentSnapshot.appendItems(items, toSection: .habits)

    var reloadIdentifiers = [CategoryDetailTableViewItem]()
    if #available(iOS 15.0, *) {
      reloadIdentifiers.append(contentsOf: fetchedSnapshot.reloadedItemIdentifiers.map { CategoryDetailTableViewItem.habit($0)
      })
    } else {
      let reloadItems: [CategoryDetailTableViewItem] = fetchedSnapshot.itemIdentifiers.compactMap { identifier in
        let transformedIdentifier = CategoryDetailTableViewItem.habit(identifier)

        guard let fetchedIndex = fetchedSnapshot.indexOfItem(identifier),
              let currentIndex = currentSnapshot.indexOfItem(transformedIdentifier),
              fetchedIndex + 1 == currentIndex else { return nil }

        guard context.object(with: identifier).isUpdated else { return nil }
        return transformedIdentifier
      }
      reloadIdentifiers.append(contentsOf: reloadItems)
    }

    currentSnapshot.reloadItems(reloadIdentifiers)
    dataSource.apply(currentSnapshot, animatingDifferences: false)
  }
}

extension CategoryDetailViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let habit = fetchResultsController.object(at: IndexPath(row: indexPath.row, section: 0))
    let editHabitViewController = EditHabitViewController(habit: habit)
    let navigationViewController = UINavigationController(rootViewController: editHabitViewController)
    present(navigationViewController, animated: true)
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section > 0 else {
      return nil
    }

    let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: CategoryDetailHabitsHeader.reuseIdentifier)
    if let headerView = headerView as? CategoryDetailHabitsHeader {
      headerView.fill(with: "Habits", category: category)
    }
    return headerView
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0 : UITableView.automaticDimension
  }

  func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    section == 0 ? 0 : 40
  }

  func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
    if proposedDestinationIndexPath.section == 0 {
      return IndexPath(row: 0, section: 1)
    } else {
      return proposedDestinationIndexPath
    }
  }
}

extension CategoryDetailViewController {
  func configureDataSource() {
    dataSource = CategoryDetailDataSource(tableView: tableView) { [unowned self] (tableView: UITableView, indexPath: IndexPath, id: CategoryDetailTableViewItem) -> UITableViewCell? in

      if case let CategoryDetailTableViewItem.habit(objectID) = id {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryDetailHabitCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? CategoryDetailHabitCell, let habit = self.context.object(with: objectID) as? Habit {
          cell.fill(with: habit)
        }
        return cell
      }

      if case let CategoryDetailTableViewItem.category(category) = id {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryDetailCell.reuseIdentifier, for: indexPath)
        if let cell = cell as? CategoryDetailCell {
          cell.fill(with: category)
          cell.delegate = self
        }
        return cell
      }
      return nil
    }
    dataSource.delegate = self
  }

  func applySnapshot() {
    var snapshot = NSDiffableDataSourceSnapshot<CategoryDetailTableViewSection, CategoryDetailTableViewItem>()
    snapshot.appendSections([.category])
    snapshot.appendItems([.category(self.category)], toSection: .category)

    snapshot.appendSections([.habits])
    dataSource.apply(snapshot)
  }

  func configureFetchedResultsController() {
    let fetchRequest = Habit.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "category == %@", category)
    fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    fetchResultsController.delegate = self

    do {
      try fetchResultsController.performFetch()
    } catch {
      let nserror = error as NSError
      fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
    }
  }
}

extension CategoryDetailViewController: CategoryDetailCellDelegate {
  func editCategory() {
    let editCategoryViewController = EditCategoryViewController(category: category)
    let navigationViewController = UINavigationController(rootViewController: editCategoryViewController)
    present(navigationViewController, animated: true)
  }
}

extension CategoryDetailViewController {
  private func setupViews() {
    view.addSubview(tableView)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
    tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
    tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
    tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    tableView.separatorStyle = .none

    tableView.register(CategoryDetailCell.self, forCellReuseIdentifier: CategoryDetailCell.reuseIdentifier)
    tableView.register(CategoryDetailHabitCell.self, forCellReuseIdentifier: CategoryDetailHabitCell.reuseIdentifier)
    tableView.register(CategoryDetailHabitsHeader.self, forHeaderFooterViewReuseIdentifier: CategoryDetailHabitsHeader.reuseIdentifier)
    tableView.delegate = self

    navigationItem.largeTitleDisplayMode = .never
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }

    editHabitsBarButton.target = self
    editHabitsBarButton.action = #selector(editHabits)
    let addHabitBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addHabit))
    navigationItem.rightBarButtonItems = [editHabitsBarButton, addHabitBarButton]

    navigationController?.isToolbarHidden = true
  }
}
